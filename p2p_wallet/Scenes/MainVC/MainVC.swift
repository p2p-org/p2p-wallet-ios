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
        view.backgroundColor = .white
    }
    
    override func mapDataToSnapshot() -> DiffableDataSourceSnapshot<String, Wallet> {
        var snapshot = super.mapDataToSnapshot()
        snapshot.appendSections(["Test"])
        return snapshot
    }
    
    override func filter(_ items: [Wallet]) -> [Wallet] {
        var wallets = [Wallet]()
        
        if let solWallet = items.first(where: {$0.symbol == "SOL"}) {
            wallets.append(solWallet)
        }
        wallets.append(
            contentsOf: items
                .filter {$0.symbol != "SOL"}
                .sorted(by: {$0.amountInUSD > $1.amountInUSD})
                .prefix(2)
        )
        
        return wallets
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(viewClass: FirstSectionHeaderView.self, title: ""),
                footer: Section.Footer(viewClass: FirstSectionFooterView.self),
                interGroupSpacing: 30,
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16),
                background: FirstSectionBackgroundView.self
            ),
            Section(
                header: Section.Header(viewClass: SecondSectionHeaderView.self, title: ""),
                background: SecondSectionBackgroundView.self
            )
        ]
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {.lightContent}
}
