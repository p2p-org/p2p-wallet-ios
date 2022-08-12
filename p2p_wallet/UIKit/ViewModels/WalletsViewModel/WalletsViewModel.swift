//
//  WalletsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import BECollectionView_Combine
import Combine
import Foundation
import Resolver
import SolanaSwift

class WalletsViewModel: BECollectionViewModel<Wallet> {
    // MARK: - Dependencies

    @Injected private var accountStorage: SolanaAccountStorage
    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var pricesService: PricesServiceType
    @Injected private var socket: AccountObservableService
    @WeakLazyInjected private var transactionHandler: TransactionHandlerType?

    // MARK: - Properties

    private var defaultsDisposables = [DefaultsDisposable]()
    private var subscriptions = [AnyCancellable]()
    private var timer: Timer?

    // MARK: - Getters

    var nativeWallet: Wallet? { data.first(where: { $0.isNativeSOL }) }

    // MARK: - Subjects

    @Published var isHiddenWalletsShown = false

    // MARK: - Initializer

    init() {
        super.init()
        bind()
        startObserving()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Binding

    override func bind() {
        super.bind()

        // observe prices
        pricesService.currentPricesPublisher
            .sink { [weak self] _ in
                self?.updatePrices()
            }
            .store(in: &subscriptions)

        // observe tokens' balance
        socket.observeAllAccountsNotifications()
            .replaceError(with: .init(pubkey: "", lamports: 0))
            .sink { [weak self] notification in
                self?.handleAccountNotification(notification)
            }
            .store(in: &subscriptions)

        // observe hideZeroBalances settings
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] _ in
            self?.updateWalletsVisibility()
        })

        // observe account notification
        $data
            .map { [weak self] _ in self?.getWallets() ?? [] }
            .sink { [weak self] wallets in
                for wallet in wallets where wallet.pubkey != nil {
                    Task { [weak self] in
                        try await self?.socket.subscribeAccountNotification(account: wallet.pubkey!)
                    }
                }
            }
            .store(in: &subscriptions)

        // observe app state
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.appDidBecomeActive()
            }
            .store(in: &subscriptions)

        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.appDidEnterBackground()
            }
            .store(in: &subscriptions)
    }

    // MARK: - Observing

    func startObserving() {
        timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true, block: { [weak self] _ in
            Task {
                try? await self?.getNewWallet()
            }
        })
    }

    func stopObserving() {
        timer?.invalidate()
    }

    // MARK: - Methods

    override func createRequest() async throws -> [Wallet] {
        guard let account = accountStorage.account?.publicKey.base58EncodedString else {
            throw SolanaError.unknown
        }
        var (balance, wallets) = try await(
            solanaAPIClient.getBalance(account: account, commitment: "recent"),
            solanaAPIClient.getTokenWallets(account: account)
        )

        // modify data on different thread
        wallets = await Task {
            // add sol wallet on top
            let solWallet = Wallet.nativeSolana(
                pubkey: accountStorage.account?.publicKey.base58EncodedString,
                lamport: balance
            )
            wallets.insert(solWallet, at: 0)

            // update visibility
            wallets = mapVisibility(wallets: wallets)

            // map prices
            wallets = mapPrices(wallets: wallets)

            // sort
            wallets.sort(by: Wallet.defaultSorter)

            return wallets
        }.value

        // retrieve prices in separated task
        let result = wallets
        Task.detached { [weak self] in
            let watchList = await self?.pricesService.getWatchList() ?? []
            let newTokens = result.map(\.token)
                .filter { !watchList.contains($0) }
            await self?.pricesService.addToWatchList(newTokens)
            try? await self?.pricesService.fetchPrices(tokens: newTokens)
        }

        return result
    }

    override func reload() {
        // disable refreshing when there is a transaction in progress
        if transactionHandler?.areSomeTransactionsInProgress() == true {
            return
        }

        super.reload()
    }

    @objc private func getNewWallet() async throws {
        guard let account = accountStorage.account?.publicKey.base58EncodedString
        else { throw SolanaError.unknown }
        let newData = try await solanaAPIClient.getTokenWallets(account: account)
        var data = self.data
        var newWallets = newData
            .filter { wl in !data.contains(where: { $0.pubkey == wl.pubkey }) }
            .filter { $0.lamports != 0 }
        newWallets = mapPrices(wallets: newWallets)
        newWallets = mapVisibility(wallets: newWallets)
        data.append(contentsOf: newWallets)
        data.sort(by: Wallet.defaultSorter)
        overrideData(by: data)
    }

    override var dataDidChange: AnyPublisher<Void, Never> {
        Publishers.CombineLatest(
            super.dataDidChange,
            $isHiddenWalletsShown.eraseToAnyPublisher()
        )
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - getters

    func hiddenWallets() -> [Wallet] {
        data.filter(\.isHidden)
    }

    // MARK: - Actions

    @objc func toggleIsHiddenWalletShown() {
        isHiddenWalletsShown = !isHiddenWalletsShown
    }

    func toggleWalletVisibility(_ wallet: Wallet) {
        if wallet.isHidden {
            unhideWallet(wallet)
        } else {
            hideWallet(wallet)
        }
    }

    // MARK: - Mappers

    private func mapPrices(wallets: [Wallet]) -> [Wallet] {
        var wallets = wallets
        for i in 0 ..< wallets.count {
            wallets[i].price = pricesService.currentPrice(for: wallets[i].token.symbol)
        }
        return wallets
    }

    private func mapVisibility(wallets: [Wallet]) -> [Wallet] {
        var wallets = wallets
        for i in 0 ..< wallets.count {
            // update visibility
            wallets[i].updateVisibility()
        }
        return wallets
    }

    // MARK: - Helpers

    private func updatePrices() {
        guard state == .loaded else { return }
        let wallets = mapPrices(wallets: data)
        overrideData(by: wallets)
    }

    private func updateWalletsVisibility() {
        guard state == .loaded else { return }
        let wallets = mapVisibility(wallets: data)
        overrideData(by: wallets)
    }

    private func hideWallet(_ wallet: Wallet) {
        Defaults.unhiddenWalletPubkey.removeAll(where: { $0 == wallet.pubkey })
        Defaults.hiddenWalletPubkey.appendIfNotExist(wallet.pubkey)
        updateVisibility(for: wallet)
    }

    private func unhideWallet(_ wallet: Wallet) {
        Defaults.unhiddenWalletPubkey.appendIfNotExist(wallet.pubkey)
        Defaults.hiddenWalletPubkey.removeAll(where: { $0 == wallet.pubkey })
        updateVisibility(for: wallet)
    }

    private func updateVisibility(for wallet: Wallet) {
        updateItem(where: {
            $0.pubkey == wallet.pubkey
        }) { wallet -> Wallet? in
            var wallet = wallet
            wallet.updateVisibility()
            return wallet
        }
    }

    // MARK: - App state

    private(set) var shouldUpdateBalance = false
    private func appDidBecomeActive() {
        // update balance
        if shouldUpdateBalance {
            Task {
                try? await getNewWallet()
            }
            shouldUpdateBalance = false
        }
    }

    private func appDidEnterBackground() {
        shouldUpdateBalance = true
    }

    // MARK: - Account notifications

    private func handleAccountNotification(_ notification: AccountsObservableEvent) {
        // update
        updateItem(where: { $0.pubkey == notification.pubkey }, transform: { wallet in
            var wallet = wallet
            wallet.lamports = notification.lamports
            return wallet
        })
    }
}

private extension Wallet {
    static var defaultSorter: (Wallet, Wallet) -> Bool {
        { lhs, rhs in
            // Solana
            if lhs.isNativeSOL != rhs.isNativeSOL {
                return lhs.isNativeSOL
            }

            if lhs.token.isLiquidity != rhs.token.isLiquidity {
                return !lhs.token.isLiquidity
            }

            if lhs.amountInCurrentFiat != rhs.amountInCurrentFiat {
                return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
            }

            if lhs.token.symbol.isEmpty != rhs.token.symbol.isEmpty {
                return !lhs.token.symbol.isEmpty
            }

            if lhs.amount != rhs.amount {
                return lhs.amount.orZero > rhs.amount.orZero
            }

            if lhs.token.symbol != rhs.token.symbol {
                return lhs.token.symbol < rhs.token.symbol
            }

            return lhs.name < rhs.name
        }
    }
}
