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
    
    lazy var avatarImageView = UIImageView(width: 30, height: 30, backgroundColor: .c4c4c4, cornerRadius: 15)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    lazy var activeStatusView = UIView(width: 8, height: 8, backgroundColor: .red, cornerRadius: 4)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .h1b1b1b
        
        // add header
        let headerView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill, arrangedSubviews: [
            avatarImageView.padding(.init(x: 0, y: 10)),
            .spacer
        ])
        
        headerView.addSubview(activeStatusView)
        activeStatusView.autoPinEdge(.top, to: .top, of: avatarImageView)
        activeStatusView.autoPinEdge(.trailing, to: .trailing, of: avatarImageView)
        
        view.addSubview(headerView.padding(.zero, backgroundColor: view.backgroundColor))
        headerView.wrapper?.autoPinEdgesToSuperviewSafeArea(with: .init(x: .defaultPadding, y: 0), excludingEdge: .bottom)
        
        // modify collectionView
        collectionView.contentInset = collectionView.contentInset.modifying(dTop: 70)
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
