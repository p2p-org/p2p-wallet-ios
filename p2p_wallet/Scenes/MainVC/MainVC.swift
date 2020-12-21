//
//  WalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import DiffableDataSources
import Action
import RxSwift

class MainVC: MyWalletsVC<MainWalletCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(interGroupSpacing: 16)
        ]
    }
    
    // MARK: - Delegate
    override func itemDidSelect(_ item: Wallet) {
        present(WalletDetailVC(wallet: item), animated: true, completion: nil)
    }
    
    // MARK: - Actions
    var receiveAction: CocoaAction {
        CocoaAction { _ in
            let vc = ReceiveTokenVC(wallets: WalletsVM.ofCurrentUser.data)
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    func sendAction(address: String? = nil) -> CocoaAction {
        CocoaAction { _ in
            let vc = SendTokenVC(wallets: self.viewModel.items, address: address)
            
            self.show(vc, sender: nil)
            return .just(())
        }
    }
    
    var swapAction: CocoaAction {
        CocoaAction { _ in
            let vc = SwapTokenVC(wallets: self.viewModel.items)
            self.show(vc, sender: nil)
            return .just(())
        }
    }
    
    var addCoinAction: CocoaAction {
        CocoaAction { _ in
            let vc = AddNewWalletVC()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    @objc func avatarImageViewDidTouch() {
        present(ProfileVC(), animated: true, completion: nil)
    }
}
