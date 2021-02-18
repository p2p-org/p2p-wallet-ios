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
    let solanaSDK: SolanaSDK
    let socket: SolanaSDK.Socket
    let transactionManager: TransactionsManager
    private(set) var myWalletsVM: WalletsVM!
    private(set) var feeVM: FeeVM!
    
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    private init() {
        self.solanaSDK = SolanaSDK(network: Defaults.network, accountStorage: AccountStorage.shared)
        self.socket = SolanaSDK.Socket(endpoint: Defaults.network.endpoint.replacingOccurrences(of: "http", with: "ws"), publicKey: solanaSDK.accountStorage.account?.publicKey)
        self.transactionManager = TransactionsManager(socket: socket)
    }
    
    // MARK: - State
    func makeMyWalletsVM() {
        self.myWalletsVM = WalletsVM(solanaSDK: solanaSDK, socket: socket, transactionManager: transactionManager)
        self.feeVM = FeeVM(solanaSDK: solanaSDK, walletsVM: myWalletsVM)
    }
    
    // MARK: - Tabbar
    func makeTabBarVC() -> TabBarVC {
        makeMyWalletsVM()
        return TabBarVC(socket: socket)
    }
    
    // MARK: - Main
    func makeMainVC() -> MainVC {
        let vm = MainVM(walletsVM: myWalletsVM)
        return MainVC(viewModel: vm)
    }
    
    func makeMyProductVC() -> MyProductsVC {
        MyProductsVC(walletsVM: myWalletsVM)
    }
    
    func makeWalletDetailVC(wallet: Wallet) -> WalletDetailVC {
        WalletDetailVC(solanaSDK: solanaSDK, walletsVM: myWalletsVM, wallet: wallet)
    }
    
    // MARK: - Settings VCs
    func makeSelectNetworkVC() -> SelectNetworkVC {
        SelectNetworkVC(solanaSDK: solanaSDK, socket: socket)
    }
    
    // MARK: - Add, Send, Receive, Swap Token VCs
    func makeAddNewTokenVC() -> AddNewWalletVC {
        let vm = _AddNewWalletVM(solanaSDK: solanaSDK, walletsVM: myWalletsVM, transactionManager: transactionManager)
        return AddNewWalletVC(viewModel: vm)
    }
    
    func makeReceiveTokenViewController() -> ReceiveTokenVC {
        ReceiveTokenVC(wallets: myWalletsVM.data)
    }
    
    func makeSendTokenViewController(activeWallet: Wallet? = nil, destinationAddress: String? = nil) -> WLModalWrapperVC {
        let vm = SendTokenViewModel(solanaSDK: solanaSDK, walletsVM: myWalletsVM, transactionManager: transactionManager, activeWallet: activeWallet, destinationAddress: destinationAddress)
        let wrappedVC = SendTokenViewController(viewModel: vm)
        let titleImageView = UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
            .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12)
        return makeCustomModalVC(wrappedVC: wrappedVC, title: L10n.send, titleImageView: titleImageView)
    }
    
    func makeSwapTokenViewController(fromWallet wallet: Wallet? = nil) -> SwapTokenViewController {
        let vm = SwapTokenViewModel(solanaSDK: solanaSDK, transactionManager: transactionManager, wallets: myWalletsVM.data, fromWallet: wallet)
        return SwapTokenViewController(viewModel: vm)
    }
    
    func makeChooseWalletVC(customFilter: ((Wallet) -> Bool)? = nil) -> ChooseWalletVC {
        ChooseWalletVC(viewModel: myWalletsVM, customFilter: customFilter)
    }
    
    func makeSwapChooseDestinationWalletVC() -> ChooseWalletVC {
        let vm = SwapChooseDestinationViewModel(solanaSDK: solanaSDK, socket: socket, walletsVM: myWalletsVM)
        let vc = ChooseWalletVC(viewModel: vm, customFilter: {_ in true})
        vm.reload()
        return vc
    }
    
    // MARK: - Other vcs
    func makeProcessTransactionVC() -> ProcessTransactionVC {
        ProcessTransactionVC(transactionManager: transactionManager)
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
}
