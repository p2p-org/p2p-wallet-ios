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

@MainActor
class WalletsViewModel: BECollectionViewModel<Wallet> {
    // MARK: - Dependencies

    @Injected private var accountStorage: SolanaAccountStorage
    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var pricesService: PricesServiceType
    @Injected private var socket: AccountObservableService
    @Injected private var tokensRepository: SolanaTokensRepository
    @WeakLazyInjected private var transactionHandler: TransactionHandlerType?

    // MARK: - Properties

    private var defaultsDisposables = [DefaultsDisposable]()
    private var subscriptions = Set<AnyCancellable>()

    private var lastGetNewWalletTime = Date()
    private var updatingTask: Task<Void, Error>?

    // MARK: - Getters

    var nativeWallet: Wallet? { data.first(where: { $0.isNativeSOL }) }

    // MARK: - Subjects

    @Published var isHiddenWalletsShown = false

    // MARK: - Initializer

    init() {
        super.init()
        bind()
    }

    // MARK: - Binding

    override func bind() {
        super.bind()

        // observe prices
        pricesService.currentPricesPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.updatePrices()
            })
            .store(in: &subscriptions)

        // observe tokens' balance
        socket.allAccountsNotificcationsPublisher
            .receive(on: DispatchQueue.main)
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
            .sink(receiveValue: { [weak self] wallets in
                for wallet in wallets where wallet.pubkey != nil {
                    Task { [weak self] in
                        try await self?.socket.subscribeAccountNotification(account: wallet.pubkey!)
                    }
                }
            })
            .store(in: &subscriptions)

        // observe timer to update
        Timer.publish(every: 10, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.updateBalancesAndGetNewWalletIfNeeded()
            })
            .store(in: &subscriptions)
    }

    // MARK: - Methods

    override func refresh() {
        state = .loading
        error = nil

        task = Task {
            do {
                let newData = try await createRequest()
                handleNewData(newData)
            } catch {
                if error is CancellationError {
                    return
                }
                handleError(error)
            }
        }
    }

    override func createRequest() async throws -> [Wallet] {
        // assertion
        guard let account = accountStorage.account?.publicKey.base58EncodedString
        else { throw SolanaError.unknown }

        // get balance/wallet
        let (balance, wallets) = try await(
            solanaAPIClient.getBalance(account: account, commitment: "processed"),
            solanaAPIClient.getTokenWallets(
                account: account,
                tokensRepository: tokensRepository
            )
        )

        // sort and map on different thread
        return await Task<[Wallet], Never> { [weak self] in
            guard let self = self else { return [] }
            var wallets = wallets

            // add sol wallet on top
            let solWallet = Wallet.nativeSolana(
                pubkey: self.accountStorage.account?.publicKey.base58EncodedString,
                lamport: balance
            )
            wallets.insert(solWallet, at: 0)

            // update visibility
            wallets = self.mapVisibility(wallets: wallets)

            // map prices
            wallets = self.mapPrices(wallets: wallets)

            // sort
            wallets.sort(by: Wallet.defaultSorter)

            return wallets
        }.value
    }

    override func handleNewData(_ newData: [Wallet]) {
        super.handleNewData(newData)
        // observe prices
        let newTokens = newData
            .filter { !self.pricesService.getWatchList().contains($0.token) || $0.price == nil }
            .compactMap { element in
                if element.token.extensions?.coingeckoId != nil {
                    return element.token
                }
                return nil
            }
        pricesService.addToWatchList(newTokens)
        pricesService.fetchPrices(tokens: newTokens, toFiat: Defaults.fiat)
    }

    override func reload() {
        // disable refreshing when there is a transaction in progress
        if transactionHandler?.areSomeTransactionsInProgress() == true {
            return
        }

        super.reload()
    }

    private func updateBalancesAndGetNewWalletIfNeeded() {
        updatingTask?.cancel()

        updatingTask = Task {
            // Update balances needs to happen every 10 secs
            guard let account = self.accountStorage.account?.publicKey.base58EncodedString
            else { throw SolanaError.unknown }

            let (solBalance, newData) = try await(
                self.solanaAPIClient.getBalance(account: account, commitment: "processed"),
                try await self.solanaAPIClient.getTokenWallets(
                    account: account,
                    tokensRepository: tokensRepository
                )
            )

            var data = self.data

            if let index = data.firstIndex(where: { $0.isNativeSOL }) {
                data[index].lamports = solBalance
            }

            // update balance
            for i in 0 ..< data.count {
                if let pubkey = data[i].pubkey,
                   let newDataIndex = newData.firstIndex(where: { $0.pubkey == pubkey })
                {
                    // check if there is any pending transaction for this account
                    let pendingTransactions = (transactionHandler?.getProccessingTransactions(of: pubkey) ?? [])
                        .filter(\.isProcessing)

                    // ignore updating balance when there is any pending transaction for this account
                    guard pendingTransactions.isEmpty else {
                        continue
                    }

                    // update balance of account
                    data[i].lamports = newData[newDataIndex].lamports
                }
            }

            // On the other hands, The process of maping, shorting is time-comsuming, so we only retrieve new wallet and
            // sort after 2 minutes
            let minComp = DateComponents(minute: 2)
            if let date = Calendar.current.date(byAdding: minComp, to: lastGetNewWalletTime),
               Date() > date
            {
                // 2 minutes has ended
                var newWallets = newData
                    .filter { wl in !data.contains(where: { $0.pubkey == wl.pubkey }) }
                    .filter { $0.lamports != 0 }

                if !newWallets.isEmpty {
                    newWallets = self.mapPrices(wallets: newWallets)
                    newWallets = self.mapVisibility(wallets: newWallets)
                    data.append(contentsOf: newWallets)
                    data.sort(by: Wallet.defaultSorter)
                }

                // save timestamp
                await MainActor.run {
                    lastGetNewWalletTime = Date()
                }
            }

            // save
            let updatedData = data
            await MainActor.run { [weak self] in
                self?.overrideData(by: updatedData)
            }
        }
    }

    override var dataDidChange: AnyPublisher<Void, Never> {
        Publishers.CombineLatest(
            $state.removeDuplicates(),
            $isHiddenWalletsShown.removeDuplicates()
        )
        .map { _ in () }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - getters

    func hiddenWallets() -> [Wallet] {
        data.filter(\.isHidden)
    }

    // MARK: - Actions

    @objc func toggleIsHiddenWalletShown() {
        isHiddenWalletsShown.toggle()
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
            wallets[i].price = pricesService.currentPrice(mint: wallets[i].token.address)
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
            .sorted(by: Wallet.defaultSorter)
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

    // MARK: - Account notifications

    private func handleAccountNotification(_ notification: AccountsObservableEvent) {
        // check if there is any pending transaction for this account
        let pendingTransactions = (transactionHandler?.getProccessingTransactions(of: notification.pubkey) ?? [])
            .filter(\.isProcessing)

        // ignore updating balance when there is any pending transaction for this account
        guard pendingTransactions.isEmpty else {
            return
        }

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
            // prefers non-liquidity token than liquidity tokens
            if lhs.token.isLiquidity != rhs.token.isLiquidity {
                return !lhs.token.isLiquidity
            }

            // prefers prioritized tokens than others
            let prioritizedTokenMints = [
                PublicKey.usdcMint.base58EncodedString,
                PublicKey.usdtMint.base58EncodedString,
            ]
            for mint in prioritizedTokenMints {
                if mint == lhs.token.address || mint == rhs.token.address {
                    return mint == lhs.token.address
                }
            }

            // prefers token which more value than the other in fiat
            if lhs.amountInCurrentFiat != rhs.amountInCurrentFiat {
                return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
            }

            // prefers known token than unknown ones
            if lhs.token.symbol.isEmpty != rhs.token.symbol.isEmpty {
                return !lhs.token.symbol.isEmpty
            }

            // prefers token which more balance than the others
            if lhs.amount != rhs.amount {
                return lhs.amount.orZero > rhs.amount.orZero
            }

            // sort by symbol
            if lhs.token.symbol != rhs.token.symbol {
                return lhs.token.symbol < rhs.token.symbol
            }

            // then name
            return lhs.name < rhs.name
        }
    }
}
