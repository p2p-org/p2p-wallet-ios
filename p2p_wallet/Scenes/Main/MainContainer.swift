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
    private(set) var myWalletsVM: WalletsVM
    
    init(rootViewModel: RootViewModel, accountStorage: KeychainAccountStorage) {
        self.rootViewModel = rootViewModel
        self.accountStorage = accountStorage
        self.solanaSDK = SolanaSDK(network: Defaults.network, accountStorage: accountStorage)
        self.socket = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: accountStorage.account?.publicKey)
        self.transactionManager = TransactionsManager(socket: socket)
        myWalletsVM = WalletsVM(solanaSDK: solanaSDK, socket: socket, transactionManager: transactionManager)
        
        defer {
            socket.connect()
        }
    }
    
    func makeMainViewController() -> MainViewController {
        MainViewController(rootViewModel: rootViewModel, scenesFactory: self)
    }
    
    func makeMainVC() -> MainVC {
        let vm = MainVM(walletsVM: myWalletsVM)
        return MainVC(viewModel: vm, scenesFactory: self)
    }
    
    func makeMyProductsVC() -> MyProductsVC {
        MyProductsVC(walletsVM: myWalletsVM, scenesFactory: self)
    }
    
    func makeWalletDetailVC(wallet: Wallet) -> WalletDetailVC {
        WalletDetailVC(solanaSDK: solanaSDK, walletsVM: myWalletsVM, wallet: wallet, scenesFactory: self)
    }
    
    func makeAddNewTokenVC() -> AddNewWalletVC {
        let vm = _AddNewWalletVM(solanaSDK: solanaSDK, walletsVM: myWalletsVM, transactionManager: transactionManager, scenesFactory: self)
        return AddNewWalletVC(viewModel: vm)
    }
    
    func makeReceiveTokenViewController() -> ReceiveTokenVC {
        ReceiveTokenVC(wallets: myWalletsVM.data)
    }
    
    func makeSendTokenViewController(activeWallet: Wallet?, destinationAddress: String?) -> WLModalWrapperVC {
        let vm = SendTokenViewModel(solanaSDK: solanaSDK, walletsVM: myWalletsVM, transactionManager: transactionManager, activeWallet: activeWallet, destinationAddress: destinationAddress)
        let wrappedVC = SendTokenViewController(viewModel: vm, scenesFactory: self)
        let titleImageView = UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
            .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12)
        return makeCustomModalVC(wrappedVC: wrappedVC, title: L10n.send, titleImageView: titleImageView)
    }
    
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapTokenViewController {
        let vm = SwapTokenViewModel(solanaSDK: solanaSDK, transactionManager: transactionManager, wallets: myWalletsVM.data, fromWallet: wallet)
        return SwapTokenViewController(viewModel: vm, scenesFactory: self)
    }
    
    func makeChooseWalletVC(customFilter: ((Wallet) -> Bool)? = nil) -> ChooseWalletVC {
        ChooseWalletVC(viewModel: myWalletsVM, sceneFactory: self, customFilter: customFilter)
    }
    
    func makeSwapChooseDestinationWalletVC(customFilter: ((Wallet) -> Bool)? = nil) -> ChooseWalletVC {
        let vm = SwapChooseDestinationViewModel(solanaSDK: solanaSDK, socket: socket, walletsVM: myWalletsVM)
        let filter = customFilter ?? {_ in true}
        let vc = ChooseWalletVC(viewModel: vm, sceneFactory: self, customFilter: filter)
        vm.reload()
        return vc
    }
    
    func makeProcessTransactionVC() -> ProcessTransactionVC {
        ProcessTransactionVC(transactionManager: transactionManager)
    }
    
    // MARK: - Profile VCs
    func makeProfileVC() -> ProfileVC {
        ProfileVC(rootViewModel: rootViewModel, scenesFactory: self)
    }
    
    func makeBackupVC() -> BackupVC {
        BackupVC(accountStorage: accountStorage, scenesFactory: self)
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
        TokenSettingsViewController(viewModel: TokenSettingsViewModel(walletsVM: myWalletsVM, pubkey: pubkey, solanaSDK: solanaSDK, transactionManager: transactionManager, accountStorage: accountStorage), scenesFactory: self)
    }
    
    // MARK: - Helpers
    func makeCustomModalVC(wrappedVC: UIViewController, title: String? = nil, titleImageView: UIView? = nil) -> WLModalWrapperVC
    {
        let vc = WLModalWrapperVC(wrapped: wrappedVC)
        vc.title = title
        vc.titleImageView = titleImageView
        vc.modalPresentationStyle = wrappedVC.modalPresentationStyle
        vc.transitioningDelegate = wrappedVC as? UIViewControllerTransitioningDelegate
        return vc
    }
    
    func changeNetwork(to network: SolanaSDK.Network) {
        Defaults.network = network
        
        self.socket.disconnect()
        self.solanaSDK = SolanaSDK(network: Defaults.network, accountStorage: accountStorage)
        self.socket = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: accountStorage.account?.publicKey)
    }
}

extension MainContainer: TabBarScenesFactory, MyWalletsScenesFactory, ProfileScenesFactory, SwapScenesFactory, WalletDetailScenesFactory, SendTokenScenesFactory, BackupScenesFactory, AddNewWalletScenesFactory, MainScenesFactory, ChangeNetworkResponder, _MainScenesFactory, TokenSettingsScenesFactory {}
