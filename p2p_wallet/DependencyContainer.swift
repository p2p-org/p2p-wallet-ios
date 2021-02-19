//
//  DependencyContainer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/02/2021.
//

import Foundation
import SolanaSwift

class DependencyContainer {
    // MARK: - Long lived dependency
    let sharedAccountStorage: KeychainAccountStorage
    var sharedSolanaSDK: SolanaSDK
    var sharedSocket: SolanaSDK.Socket
    let sharedTransactionManager: TransactionsManager
    private(set) var sharedMyWalletsVM: WalletsVM!
    
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    init() {
        self.sharedAccountStorage = KeychainAccountStorage()
        self.sharedSolanaSDK = SolanaSDK(network: Defaults.network, accountStorage: sharedAccountStorage)
        self.sharedSocket = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: sharedSolanaSDK.accountStorage.account?.publicKey)
        self.sharedTransactionManager = TransactionsManager(socket: sharedSocket)
    }
    
    // MARK: - State
    func makeMyWalletsVM() {
        self.sharedMyWalletsVM = WalletsVM(solanaSDK: sharedSolanaSDK, socket: sharedSocket, transactionManager: sharedTransactionManager)
    }
    
    // MARK: - Root
    func makeRootViewController() -> RootViewController {
        let viewModel = RootViewModel(accountStorage: sharedAccountStorage)
        return RootViewController(viewModel: viewModel)
    }
    
    // MARK: - Authentication
    func makeLocalAuthVC() -> LocalAuthVC {
        LocalAuthVC(accountStorage: sharedAccountStorage)
    }
    
    // MARK: - Onboarding
    func makeRestoreWalletVC() -> RestoreWalletVC {
        RestoreWalletVC(accountStorage: sharedAccountStorage)
    }
    
    func makeSSPinCodeVC() -> SSPinCodeVC {
        SSPinCodeVC(accountStorage: sharedAccountStorage)
    }
    
    func makeWelcomeBackVC(phrases: [String]) -> WelcomeBackVC {
        WelcomeBackVC(phrases: phrases, accountStorage: sharedAccountStorage)
    }
    
    // MARK: - Tabbar
    func makeTabBarVC() -> TabBarVC {
        makeMyWalletsVM()
        return TabBarVC(socket: sharedSocket)
    }
    
    // MARK: - Main
    func makeMainVC() -> MainVC {
        let vm = MainVM(walletsVM: sharedMyWalletsVM)
        return MainVC(viewModel: vm)
    }
    
    func makeMyProductVC() -> MyProductsVC {
        MyProductsVC(walletsVM: sharedMyWalletsVM)
    }
    
    func makeWalletDetailVC(wallet: Wallet) -> WalletDetailVC {
        WalletDetailVC(solanaSDK: sharedSolanaSDK, walletsVM: sharedMyWalletsVM, wallet: wallet)
    }
    
    // MARK: - Profile VCs
    func makeProfileVC() -> ProfileVC {
        ProfileVC(accountStorage: sharedAccountStorage)
    }
    
    func makeBackupMannuallyVC() -> BackupManuallyVC {
        BackupManuallyVC(accountStorage: sharedAccountStorage)
    }
    
    func makeSelectNetworkVC() -> SelectNetworkVC {
        SelectNetworkVC(accountStorage: sharedAccountStorage)
    }
    
    func makeBackupVC() -> BackupVC {
        BackupVC(accountStorage: sharedAccountStorage)
    }
    
    func makeConfigureSecurityVC() -> ConfigureSecurityVC {
        ConfigureSecurityVC(accountStorage: sharedAccountStorage)
    }
    
    func makeCreatePhrasesVC() -> CreatePhrasesVC {
        CreatePhrasesVC(accountStorage: sharedAccountStorage)
    }
    
    // MARK: - Add, Send, Receive, Swap Token VCs
    func makeAddNewTokenVC() -> AddNewWalletVC {
        let vm = _AddNewWalletVM(solanaSDK: sharedSolanaSDK, walletsVM: sharedMyWalletsVM, transactionManager: sharedTransactionManager)
        return AddNewWalletVC(viewModel: vm)
    }
    
    func makeReceiveTokenViewController() -> ReceiveTokenVC {
        ReceiveTokenVC(wallets: sharedMyWalletsVM.data)
    }
    
    func makeSendTokenViewController(activeWallet: Wallet? = nil, destinationAddress: String? = nil) -> WLModalWrapperVC {
        let vm = SendTokenViewModel(solanaSDK: sharedSolanaSDK, walletsVM: sharedMyWalletsVM, transactionManager: sharedTransactionManager, activeWallet: activeWallet, destinationAddress: destinationAddress)
        let wrappedVC = SendTokenViewController(viewModel: vm)
        let titleImageView = UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
            .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12)
        return makeCustomModalVC(wrappedVC: wrappedVC, title: L10n.send, titleImageView: titleImageView)
    }
    
    func makeSwapTokenViewController(fromWallet wallet: Wallet? = nil) -> SwapTokenViewController {
        let vm = SwapTokenViewModel(solanaSDK: sharedSolanaSDK, transactionManager: sharedTransactionManager, wallets: sharedMyWalletsVM.data, fromWallet: wallet)
        return SwapTokenViewController(viewModel: vm)
    }
    
    func makeChooseWalletVC(customFilter: ((Wallet) -> Bool)? = nil) -> ChooseWalletVC {
        ChooseWalletVC(viewModel: sharedMyWalletsVM, customFilter: customFilter)
    }
    
    func makeSwapChooseDestinationWalletVC() -> ChooseWalletVC {
        let vm = SwapChooseDestinationViewModel(solanaSDK: sharedSolanaSDK, socket: sharedSocket, walletsVM: sharedMyWalletsVM)
        let vc = ChooseWalletVC(viewModel: vm, customFilter: {_ in true})
        vm.reload()
        return vc
    }
    
    // MARK: - Other vcs
    func makeProcessTransactionVC() -> ProcessTransactionVC {
        ProcessTransactionVC(transactionManager: sharedTransactionManager)
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
    
    func changeNetwork() {
        self.sharedSocket.disconnect()
        self.sharedSolanaSDK = SolanaSDK(network: Defaults.network, accountStorage: sharedAccountStorage)
        self.sharedSocket = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: self.sharedSolanaSDK.accountStorage.account?.publicKey)
    }
}
