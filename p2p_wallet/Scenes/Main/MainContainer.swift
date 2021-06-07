//
//  MainContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation
import RxSwift

class MainContainer {
    let rootViewModel: RootViewModel
    
    let accountStorage: KeychainAccountStorage
    var solanaSDK: SolanaSDK
    var socket: SolanaSDK.Socket
    let transactionManager: TransactionsManager
    let pricesManager: PricesManager
    private(set) var walletsViewModel: WalletsViewModel
    
    init(rootViewModel: RootViewModel, accountStorage: KeychainAccountStorage) {
        self.rootViewModel = rootViewModel
        self.accountStorage = accountStorage
        self.solanaSDK = SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: accountStorage)
        self.socket = SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl)
        self.transactionManager = TransactionsManager(socket: socket)
        self.pricesManager = PricesManager(tokensRepository: solanaSDK, fetcher: CryptoComparePricesFetcher(), refreshAfter: 10 * 1000) // 10minutes
        
        self.walletsViewModel = WalletsViewModel(solanaSDK: solanaSDK, socket: socket, transactionManager: transactionManager, pricesRepository: pricesManager)
        
        defer {
            socket.connect()
//            pricesManager.startObserving()
        }
    }
    
    func makeMainViewController() -> MainViewController {
        MainViewController(rootViewModel: rootViewModel, scenesFactory: self)
    }
    
    func makeTabBarVC() -> TabBarVC {
        TabBarVC(scenesFactory: self)
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
    
    func makeWalletDetailViewController(pubkey: String, symbol: String) -> WalletDetailViewController {
        let viewModel = WalletDetailViewModel(
            walletPubkey: pubkey,
            walletSymbol: symbol,
            solanaSDK: solanaSDK,
            walletsRepository: walletsViewModel,
            pricesRepository: pricesManager
        )
        return WalletDetailViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeTransactionInfoViewController(transaction: SolanaSDK.AnyTransaction) -> TransactionInfoViewController
    {
        let viewModel = TransactionInfoViewModel(transaction: transaction)
        return TransactionInfoViewController(viewModel: viewModel)
    }
    
    func makeReceiveTokenViewController(pubkey: String? = nil) -> ReceiveTokenViewController {
        let viewModel = ReceiveTokenViewModel(
            createTokenHandler: solanaSDK,
            transactionHandler: socket,
            walletsRepository: walletsViewModel,
            pubkey: pubkey
        )
        return ReceiveTokenViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController {
        let vm = SendToken.ViewModel(
            repository: walletsViewModel,
            walletPubkey: walletPubkey,
            destinationAddress: destinationAddress,
            apiClient: solanaSDK,
            authenticationHandler: rootViewModel
        )
        let vc = SendToken.ViewController(viewModel: vm, scenesFactory: self)
        return vc
    }
    
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapToken.ViewController
    {
        let vm = SwapToken.ViewModel(
            apiClient: solanaSDK,
            authenticationHandler: rootViewModel
        )
        vm.input.sourceWallet.accept(wallet)
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
    
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<SolanaSDK.TransactionID>) -> ProcessTransaction.ViewController {
        let viewModel = ProcessTransaction.ViewModel(
            transactionType: transactionType,
            request: request,
            transactionHandler: socket,
            transactionManager: transactionManager,
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
        BackupVC(accountStorage: accountStorage, authenticationHandler: rootViewModel, scenesFactory: self)
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
        ConfigureSecurityVC(accountStorage: accountStorage, rootViewModel: rootViewModel)
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
            rootViewModel: rootViewModel,
            scenesFactory: self
        )
    }
    
    // MARK: - Helpers
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint) -> Completable {
        Completable.create {observer in
            DispatchQueue.global().async { [unowned self] in
                do {
                    let account = try SolanaSDK.Account(phrase: self.accountStorage.account!.phrase, network: endpoint.network)
                    try self.accountStorage.save(account)
                    DispatchQueue.main.async {
                        Defaults.apiEndPoint = endpoint
                        self.socket.disconnect()
                        self.solanaSDK = SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: accountStorage)
                        self.socket = SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl)
                        observer(.completed)
                        self.rootViewModel.reload()
                    }
                } catch {
                    DispatchQueue.main.async {
                        observer(.error(error))
                    }
                }
            }
            return Disposables.create()
        }
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
                         ReceiveTokenSceneFactory,
                         TokenSettingsScenesFactory,
                         _MainScenesFactory {}
