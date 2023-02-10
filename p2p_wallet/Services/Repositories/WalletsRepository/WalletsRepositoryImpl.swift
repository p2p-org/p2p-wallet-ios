import Foundation
import Resolver
import SolanaSwift
import Combine
import RxCombine

class WalletsRepositoryImpl: ListRepository<Wallet> {
    // MARK: - Dependencies

    @Injected private var accountStorage: SolanaAccountStorage
    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var pricesService: PricesServiceType
    @Injected private var socket: AccountObservableService
    @WeakLazyInjected private var transactionHandler: TransactionHandlerType?

    // MARK: - Properties

    private var defaultsDisposables = [DefaultsDisposable]()
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor private var lastGetNewWalletTime = Date()
    private var updatingTask: Task<Void, Error>?

    // MARK: - Getters

    var nativeWallet: Wallet? { data.first(where: { $0.isNativeSOL }) }

    // MARK: - Subjects

    let isHiddenWalletsShown = CurrentValueSubject<Bool, Never>(false)

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
        socket.observeAllAccountsNotifications()
            .map(Optional.init)
            .publisher
            .replaceError(with: nil)
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleAccountNotification(notification)
            }
            .store(in: &subscriptions)

        // observe hideZeroBalances settings
        defaultsDisposables.append(Defaults.observe(\.hideZeroBalances) { [weak self] _ in
            self?.updateWalletsVisibility()
        })

        // observe account notification
        dataPublisher
            .map { [weak self] _ in self?.getWallets() ?? [] }
            .sink { [weak self] wallets in
                for wallet in wallets where wallet.pubkey != nil {
                    Task { [weak self] in
                        try await self?.socket.subscribeAccountNotification(account: wallet.pubkey!)
                    }
                }
            }
            .store(in: &subscriptions)

        // observe timer to update
        Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink {[weak self] _ in
                self?.updateBalancesAndGetNewWalletIfNeeded()
            }
            .store(in: &subscriptions)
    }

    // MARK: - Methods

    override func createRequest() async throws -> [Wallet] {
        guard let account = self.accountStorage.account?.publicKey.base58EncodedString
        else { throw SolanaError.unknown }
        
        // get balances and wallet
        let (balance, wallets) = try await(
            self.solanaAPIClient.getBalance(account: account, commitment: "recent"),
            self.solanaAPIClient.getTokenWallets(account: account)
        )
        
        // sort in separated task
        let sortedWallets = try await Task { [ weak self] in
            
            guard let self = self else {
                throw CancellationError()
            }
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
        
        // fetch prices for new tokens
        let newTokens = wallets.map(\.token)
            .filter { !pricesService.getWatchList().contains($0) }
        pricesService.addToWatchList(newTokens)
        pricesService.fetchPrices(tokens: newTokens, toFiat: Defaults.fiat)
        
        return sortedWallets
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
                self.solanaAPIClient.getBalance(account: account, commitment: "recent"),
                try await self.solanaAPIClient.getTokenWallets(account: account)
            )
            
            var data = self.data
            
            if !data.isEmpty {
                data[0].lamports = solBalance
            }
            
            // update balance
            for i in 0..<data.count  {
                if let newDataIndex = newData.firstIndex(where: {$0.pubkey == data[i].pubkey})
                {
                    data[i].lamports = newData[newDataIndex].lamports
                }
            }
            
            // On the other hands, The process of maping, shorting is time-comsuming, so we only retrieve new wallet and sort after 2 minutes
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
            super.dataDidChange,
            isHiddenWalletsShown.removeDuplicates()
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
        isHiddenWalletsShown.send(!isHiddenWalletsShown.value)
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
