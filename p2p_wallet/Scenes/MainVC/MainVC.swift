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
    
    // MARK: - Subviews
    var collectionViewHeaderView: FirstSectionHeaderView?
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        
        // headerView
        configureHeaderView()
        
        // modify collectionView
        collectionView.contentInset = collectionView.contentInset.modifying(dTop: 10+25+10)
    }
    
    // MARK: - Binding
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletsVM
        
        // fix header
        collectionViewHeaderView?.setUp(state: viewModel.state.value)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(
                    viewClass: FirstSectionHeaderView.self,
                    title: L10n.wallets),
                interGroupSpacing: 16
            ),
            Section(
                header: Section.Header(title: L10n.savings),
                interGroupSpacing: 16)
        ]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        if indexPath.section == 0,
           let view = header as? FirstSectionHeaderView
        {
            view.receiveAction = self.receiveAction
            view.sendAction = self.sendAction()
            view.swapAction = self.swapAction
            view.addCoinButton.rx.action = self.addCoinAction
            collectionViewHeaderView = view
        }
        
        return header
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
    
    // MARK: - Private
    private func configureHeaderView() {
        let statusBarBgView = UIView(backgroundColor: view.backgroundColor)
        view.addSubview(statusBarBgView)
        statusBarBgView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        statusBarBgView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            .isActive = true
    }
}

extension MainVC {
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if indexPath.section == 0
        {
            if elementKind == UICollectionView.elementKindSectionHeader {
                collectionViewHeaderView = nil
            }
        }
    }
}
