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
    let myWalletsVM: WalletsVM
    
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    private init() {
        self.solanaSDK = SolanaSDK.shared
        self.myWalletsVM = WalletsVM.ofCurrentUser
    }
    
    // MARK: - Factory methods
    func makeCustomModalVC(wrappedVC: UIViewController, title: String? = nil, titleImageView: UIView? = nil) -> WLModalWrapperVC
    {
        let vc = WLModalWrapperVC(wrapped: wrappedVC)
        vc.title = title
        vc.titleImageView = titleImageView
        vc.modalPresentationStyle = wrappedVC.modalPresentationStyle
        vc.transitioningDelegate = wrappedVC as? UIViewControllerTransitioningDelegate
        return vc
    }
    
    func makeSendTokenViewController(activeWallet: Wallet? = nil, destinationAddress: String? = nil) -> WLModalWrapperVC {
        let vm = SendTokenViewModel(wallets: myWalletsVM.data, activeWallet: activeWallet, destinationAddress: destinationAddress)
        let wrappedVC = SendTokenViewController(viewModel: vm)
        let titleImageView = UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
            .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12)
        return makeCustomModalVC(wrappedVC: wrappedVC, title: L10n.send, titleImageView: titleImageView)
    }
    
    func makeSwapTokenViewController(fromWallet wallet: Wallet? = nil) -> SwapTokenViewController {
        let vm = SwapTokenViewModel(wallets: myWalletsVM.data, fromWallet: wallet)
        return SwapTokenViewController(viewModel: vm)
    }
}
