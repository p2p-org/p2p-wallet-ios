//
//  MainContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/02/2021.
//

import Foundation

class MainContainer {
    let rootViewModel: RootViewModel
    
    let accountStorage: KeychainAccountStorage
    var solanaSDK: SolanaSDK
    var socket: SolanaSDK.Socket
    let transactionManager: TransactionsManager
    let pricesManager: PricesManager
    private(set) var myWalletsVM: WalletsVM
    
    init(rootViewModel: RootViewModel, accountStorage: KeychainAccountStorage) {
        self.rootViewModel = rootViewModel
        self.accountStorage = accountStorage
        self.solanaSDK = SolanaSDK(network: Defaults.network, accountStorage: accountStorage)
        self.socket = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: accountStorage.account?.publicKey)
        self.transactionManager = TransactionsManager(socket: socket)
        myWalletsVM = WalletsVM(solanaSDK: solanaSDK, socket: socket, transactionManager: transactionManager)
        pricesManager = PricesManager.shared
        
        defer {
            socket.connect()
        }
    }
    
    func makeMainViewController() -> MainViewController {
        MainViewController(rootViewModel: rootViewModel, scenesFactory: self)
    }
    
    func makeTabBarVC() -> TabBarVC {
        TabBarVC(scenesFactory: self)
    }
    
    func makeHomeViewController() -> HomeViewController {
        let vm = HomeViewModel(walletsVM: myWalletsVM)
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
        let viewModel = MyProductsViewModel(walletsVM: myWalletsVM)
        return MyProductsViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeWalletDetailViewController(pubkey: String, symbol: String) -> WalletDetailViewController {
        let viewModel = WalletDetailViewModel(
            walletPubkey: pubkey,
            walletSymbol: symbol,
            solanaSDK: solanaSDK,
            walletsRepository: myWalletsVM,
            pricesRepository: pricesManager
        )
        return WalletDetailViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeTransactionInfoViewController(transaction: SolanaSDK.AnyTransaction) -> TransactionInfoViewController
    {
        let viewModel = TransactionInfoViewModel(transaction: transaction)
        return TransactionInfoViewController(viewModel: viewModel)
    }
    
    func makeAddNewTokenVC() -> AddNewWalletVC {
        let vm = _AddNewWalletVM(handler: solanaSDK, walletsVM: myWalletsVM, transactionManager: transactionManager, scenesFactory: self)
        return AddNewWalletVC(viewModel: vm)
    }
    
    func makeReceiveTokenViewController(pubkey: String? = nil) -> ReceiveTokenViewController {
        let viewModel = ReceiveTokenViewModel(
            createTokenHandler: solanaSDK,
            transactionHandler: socket,
            walletsRepository: myWalletsVM,
            pubkey: pubkey
        )
        return ReceiveTokenViewController(viewModel: viewModel, scenesFactory: self)
    }
    
    func makeSendTokenViewController(activeWallet: Wallet?, destinationAddress: String?) -> SendTokenViewController {
        let vm = SendTokenViewModel(solanaSDK: solanaSDK, walletsVM: myWalletsVM, transactionManager: transactionManager, activeWallet: activeWallet, destinationAddress: destinationAddress)
        let vc = SendTokenViewController(viewModel: vm, scenesFactory: self)
        return vc
    }
    
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapTokenViewController {
        let vm = SwapTokenViewModel(solanaSDK: solanaSDK, transactionManager: transactionManager, wallets: myWalletsVM.data, fromWallet: wallet)
        return SwapTokenViewController(viewModel: vm, scenesFactory: self)
    }
    
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool) -> ChooseWalletViewController {
        let viewModel = ChooseWalletViewModel(
            myWalletsViewModel: myWalletsVM,
            showOtherWallets: showOtherWallets)
        { (item) -> Bool in
            guard let customFilter = customFilter else {return true}
            guard let item = item as? Wallet else {return false}
            return customFilter(item)
        }
        return ChooseWalletViewController(viewModel: viewModel)
    }
    
    // MARK: - Profile VCs
    func makeProfileVC() -> ProfileVC {
        ProfileVC(accountStorage: accountStorage, rootViewModel: rootViewModel, scenesFactory: self)
    }
    
    func makeBackupVC() -> BackupVC {
        BackupVC(accountStorage: accountStorage, rootViewModel: rootViewModel, scenesFactory: self)
    }
    
    func makeBackupManuallyVC() -> BackupManuallyVC {
        BackupManuallyVC(accountStorage: accountStorage)
    }
    
    func makeSelectNetworkVC() -> SelectNetworkVC {
        SelectNetworkVC(accountStorage: accountStorage, rootViewModel: rootViewModel, changeNetworkResponder: self)
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
        TokenSettingsViewController(viewModel: TokenSettingsViewModel(walletsVM: myWalletsVM, pubkey: pubkey, solanaSDK: solanaSDK, transactionManager: transactionManager, accountStorage: accountStorage), rootViewModel: rootViewModel)
    }
    
    // MARK: - Helpers
    func changeNetwork(to network: SolanaSDK.Network) {
        Defaults.network = network
        
        self.socket.disconnect()
        self.solanaSDK = SolanaSDK(network: Defaults.network, accountStorage: accountStorage)
        self.socket = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: accountStorage.account?.publicKey)
    }
}

extension MainContainer: TabBarScenesFactory,
                         MyProductsScenesFactory,
                         ProfileScenesFactory,
                         SwapScenesFactory,
                         WalletDetailScenesFactory,
                         SendTokenScenesFactory,
                         BackupScenesFactory,
                         AddNewWalletScenesFactory,
                         HomeScenesFactory,
                         ChangeNetworkResponder,
                         ReceiveTokenSceneFactory,
                         _MainScenesFactory {}
