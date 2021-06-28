//
//  MainContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation
import RxSwift

class MainContainer {
    let rootViewModel: Root.ViewModel
    
    let accountStorage: KeychainAccountStorage
    var solanaSDK: SolanaSDK
    var socket: SolanaSDK.Socket
    let processingTransactionsManager: ProcessingTransactionsManager
    let pricesManager: PricesManager
    private(set) var walletsViewModel: WalletsViewModel
    
    let mainViewModel: MainViewModel
    let analyticsManager: AnalyticsManagerType
    
    init(rootViewModel: Root.ViewModel, accountStorage: KeychainAccountStorage, analyticsManager: AnalyticsManagerType) {
        self.rootViewModel = rootViewModel
        self.accountStorage = accountStorage
        self.solanaSDK = SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: accountStorage)
        self.socket = SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl)
        self.processingTransactionsManager = ProcessingTransactionsManager(handler: socket)
        self.pricesManager = PricesManager(tokensRepository: solanaSDK, fetcher: CryptoComparePricesFetcher(), refreshAfter: 2 * 1000) // 2 minutes
        
        self.walletsViewModel = WalletsViewModel(
            solanaSDK: solanaSDK,
            socket: socket,
            processingTransactionRepository: processingTransactionsManager,
            pricesRepository: pricesManager
        )
        
        self.mainViewModel = MainViewModel()
        self.analyticsManager = analyticsManager
        
        defer {
            socket.connect()
            pricesManager.startObserving()
        }
    }
    
    deinit {
        socket.disconnect()
        pricesManager.stopObserving()
    }
    
    func makeMainViewController(authenticateWhenAppears: Bool) -> MainViewController {
        MainViewController(viewModel: mainViewModel, scenesFactory: self, authenticateWhenAppears: authenticateWhenAppears)
    }
    
    func makeTabBarVC() -> TabBarVC {
        TabBarVC(scenesFactory: self)
    }
    
    // MARK: - Authentication
    func makeLocalAuthVC() -> LocalAuthVC {
        LocalAuthVC(accountStorage: accountStorage)
    }
    
    // MARK: - Reset pincode with seed phrases
    func makeResetPinCodeWithSeedPhrasesViewController() -> ResetPinCodeWithSeedPhrasesViewController
    {
        let container = ResetPinCodeWithSeedPhrasesContainer(accountRepository: accountStorage)
        return container.makeResetPinCodeWithSeedPhrasesViewController()
    }
    
    func makeHomeViewController() -> HomeViewController {
        let vm = HomeViewModel(walletsRepository: walletsViewModel)
        return HomeViewController(viewModel: vm, scenesFactory: self, analyticsManager: analyticsManager)
    }
    
    func makeInvestmentsViewController() -> InvestmentsViewController {
        let newsViewModel = NewsViewModel()
        let defisViewModel = DefisViewModel()
        let investmentsViewModel = InvestmentsViewModel(
            newsViewModel: newsViewModel,
            defisViewModel: defisViewModel
        )
        return InvestmentsViewController(viewModel: investmentsViewModel)
    }
    
    func makeMyProductsViewController() -> MyProductsViewController {
        let viewModel = MyProductsViewModel(walletsRepository: walletsViewModel)
        return MyProductsViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeWalletDetailViewController(pubkey: String, symbol: String) -> WalletDetail.ViewController {
        let viewModel = WalletDetail.ViewModel(
            pubkey: pubkey,
            symbol: symbol,
            walletsRepository: walletsViewModel,
            processingTransactionRepository: processingTransactionsManager,
            pricesRepository: pricesManager,
            transactionsRepository: solanaSDK,
            analyticsManager: analyticsManager,
            feeRelayerAPIClient: solanaSDK
        )
        
        return WalletDetail.ViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeTransactionInfoViewController(transaction: ParsedTransaction) -> TransactionInfoViewController
    {
        let viewModel = TransactionInfoViewModel(transaction: transaction)
        return TransactionInfoViewController(viewModel: viewModel)
    }
    
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController? {
        guard let pubkey = walletsViewModel.solWallet?.pubkey else {return nil}
        let tokenWallet = walletsViewModel.getWallets().first(where: {$0.pubkey == tokenWalletPubkey})
        let viewModel = ReceiveToken.ViewModel(pubkey: pubkey, tokenWallet: tokenWallet, analyticsManager: analyticsManager)
        return ReceiveToken.ViewController(viewModel: viewModel)
    }
    
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController {
        let vm = SendToken.ViewModel(
            repository: walletsViewModel,
            walletPubkey: walletPubkey,
            destinationAddress: destinationAddress,
            apiClient: solanaSDK,
            authenticationHandler: mainViewModel,
            analyticsManager: analyticsManager
        )
        let vc = SendToken.ViewController(viewModel: vm, scenesFactory: self)
        return vc
    }
    
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapToken.ViewController
    {
        let vm = SwapToken.ViewModel(
            solWallet: walletsViewModel.solWallet,
            apiClient: solanaSDK,
            authenticationHandler: mainViewModel,
            analyticsManager: analyticsManager
        )
        vm.input.sourceWallet.accept(wallet ?? walletsViewModel.solWallet)
        return SwapToken.ViewController(viewModel: vm, scenesFactory: self)
    }
    
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool) -> ChooseWalletViewController {
        let viewModel = ChooseWalletViewModel(
            myWalletsViewModel: walletsViewModel,
            tokensRepository: solanaSDK,
            showOtherWallets: showOtherWallets)
        { (item) -> Bool in
            guard let customFilter = customFilter else {return true}
            guard let item = item as? Wallet else {return false}
            return customFilter(item)
        }
        return ChooseWalletViewController(viewModel: viewModel)
    }
    
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController {
        let viewModel = ProcessTransaction.ViewModel(
            transactionType: transactionType,
            request: request,
            transactionHandler: processingTransactionsManager,
            walletsRepository: walletsViewModel,
            pricesRepository: pricesManager,
            apiClient: solanaSDK,
            analyticsManager: analyticsManager
        )
        return ProcessTransaction.ViewController(viewModel: viewModel)
    }
    
    // MARK: - Profile VCs
    func makeProfileVC() -> ProfileVC {
        ProfileVC(accountStorage: accountStorage, rootViewModel: rootViewModel, scenesFactory: self, analyticsManager: analyticsManager)
    }
    
    func makeBackupVC() -> BackupVC {
        BackupVC(accountStorage: accountStorage, authenticationHandler: mainViewModel, scenesFactory: self, analyticsManager: analyticsManager)
    }
    
    func makeBackupManuallyVC() -> BackupManuallyVC {
        BackupManuallyVC(accountStorage: accountStorage)
    }
    
    func makeSelectFiatVC() -> SelectFiatVC {
        SelectFiatVC(responder: self, analyticsManager: analyticsManager)
    }
    
    func makeSelectNetworkVC() -> SelectNetworkVC {
        SelectNetworkVC(changeNetworkResponder: rootViewModel, analyticsManger: analyticsManager)
    }
    
    func makeConfigureSecurityVC() -> ConfigureSecurityVC {
        ConfigureSecurityVC(accountStorage: accountStorage, authenticationHandler: mainViewModel, analyticsManager: analyticsManager)
    }
    
    func makeSelectLanguageVC() -> SelectLanguageVC {
        SelectLanguageVC(responder: rootViewModel)
    }
    
    func makeSelectAppearanceVC() -> SelectAppearanceVC {
        SelectAppearanceVC(analyticsManager: analyticsManager)
    }
    
    // MARK: - Token edit
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController {
        TokenSettingsViewController(
            viewModel: TokenSettingsViewModel(
                walletsRepository: walletsViewModel,
                pubkey: pubkey,
                solanaSDK: solanaSDK,
                pricesRepository: pricesManager,
                accountStorage: accountStorage
            ),
            authenticationHandler: mainViewModel,
            scenesFactory: self
        )
    }
    
    // MARK: - Helpers
    func changeFiat(to fiat: Fiat) {
        Defaults.fiat = fiat
        pricesManager.currentPrices.accept([:])
        pricesManager.fetchAllTokensPrice()
    }
}

extension MainContainer: TabBarScenesFactory,
                         MyProductsScenesFactory,
                         ProfileScenesFactory,
                         SwapTokenScenesFactory,
                         WalletDetailScenesFactory,
                         SendTokenScenesFactory,
                         BackupScenesFactory,
                         HomeScenesFactory,
                         ChangeFiatResponder,
                         TokenSettingsScenesFactory,
                         _MainScenesFactory {}
