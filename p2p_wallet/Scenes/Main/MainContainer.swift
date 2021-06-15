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
    
    init(rootViewModel: Root.ViewModel, accountStorage: KeychainAccountStorage) {
        self.rootViewModel = rootViewModel
        self.accountStorage = accountStorage
        self.solanaSDK = SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: accountStorage)
        self.socket = SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl)
        self.processingTransactionsManager = ProcessingTransactionsManager(handler: socket)
        self.pricesManager = PricesManager(tokensRepository: solanaSDK, fetcher: CryptoComparePricesFetcher(), refreshAfter: 10 * 1000) // 10minutes
        
        self.walletsViewModel = WalletsViewModel(
            solanaSDK: solanaSDK,
            socket: socket,
            processingTransactionRepository: processingTransactionsManager,
            pricesRepository: pricesManager
        )
        
        self.mainViewModel = MainViewModel()
        
        defer {
            socket.connect()
//            pricesManager.startObserving()
        }
    }
    
    func makeMainViewController(authenticateWhenAppears: Bool) -> MainViewController {
        MainViewController(viewModel: mainViewModel, scenesFactory: self, authenticateWhenAppears: authenticateWhenAppears)
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
        return HomeViewController(viewModel: vm, scenesFactory: self)
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
            pricesRepository: pricesManager,
            transactionsRepository: solanaSDK
        )
        
        return WalletDetail.ViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeTransactionInfoViewController(transaction: SolanaSDK.AnyTransaction) -> TransactionInfoViewController
    {
        let viewModel = TransactionInfoViewModel(transaction: transaction)
        return TransactionInfoViewController(viewModel: viewModel)
    }
    
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController? {
        guard let pubkey = walletsViewModel.solWallet?.pubkey else {return nil}
        let tokenWallet = walletsViewModel.getWallets().first(where: {$0.pubkey == tokenWalletPubkey})
        let viewModel = ReceiveToken.ViewModel(pubkey: pubkey, tokenWallet: tokenWallet)
        return ReceiveToken.ViewController(viewModel: viewModel)
    }
    
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController {
        let vm = SendToken.ViewModel(
            repository: walletsViewModel,
            walletPubkey: walletPubkey,
            destinationAddress: destinationAddress,
            apiClient: solanaSDK,
            authenticationHandler: mainViewModel
        )
        let vc = SendToken.ViewController(viewModel: vm, scenesFactory: self)
        return vc
    }
    
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapToken.ViewController
    {
        let vm = SwapToken.ViewModel(
            apiClient: solanaSDK,
            authenticationHandler: mainViewModel
        )
        vm.input.sourceWallet.accept(wallet ?? walletsViewModel.solWallet)
        return SwapToken.ViewController(viewModel: vm, scenesFactory: self)
    }
    
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool) -> ChooseWalletViewController {
        let viewModel = ChooseWalletViewModel(
            myWalletsViewModel: walletsViewModel,
            tokensRepository: solanaSDK,
            pricesRepository: pricesManager,
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
            apiClient: solanaSDK
        )
        return ProcessTransaction.ViewController(viewModel: viewModel)
    }
    
    // MARK: - Profile VCs
    func makeProfileVC() -> ProfileVC {
        ProfileVC(accountStorage: accountStorage, rootViewModel: rootViewModel, scenesFactory: self)
    }
    
    func makeBackupVC() -> BackupVC {
        BackupVC(accountStorage: accountStorage, authenticationHandler: mainViewModel, scenesFactory: self)
    }
    
    func makeBackupManuallyVC() -> BackupManuallyVC {
        BackupManuallyVC(accountStorage: accountStorage)
    }
    
    func makeSelectFiatVC() -> SelectFiatVC {
        SelectFiatVC(responder: self)
    }
    
    func makeSelectNetworkVC() -> SelectNetworkVC {
        SelectNetworkVC(changeNetworkResponder: self)
    }
    
    func makeConfigureSecurityVC() -> ConfigureSecurityVC {
        ConfigureSecurityVC(accountStorage: accountStorage, authenticationHandler: mainViewModel)
    }
    
    func makeSelectLanguageVC() -> SelectLanguageVC {
        SelectLanguageVC(rootViewModel: rootViewModel)
    }
    
    func makeSelectAppearanceVC() -> SelectAppearanceVC {
        SelectAppearanceVC(rootViewModel: rootViewModel)
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
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint) {
        Defaults.apiEndPoint = endpoint
        accountStorage.removeAccountCache()
        
        socket.disconnect()
        solanaSDK = SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: accountStorage)
        socket = SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl)
        
        rootViewModel.reload()
    }
    
    func changeFiat(to fiat: Fiat) {
        Defaults.fiat = fiat
        pricesManager.currentPrices.accept([:])
        rootViewModel.reload()
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
                         ChangeNetworkResponder,
                         ChangeFiatResponder,
                         TokenSettingsScenesFactory,
                         _MainScenesFactory {}
