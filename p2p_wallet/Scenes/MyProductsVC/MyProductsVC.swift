//
//  MyProductsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation

class MyProductsVC: MyWalletsVC {
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(viewClass: FirstSectionHeaderView.self, title: L10n.balances, titleFont: .systemFont(ofSize: 17, weight: .semibold)),
                cellType: MyProductsWalletCell.self,
                interGroupSpacing: 30,
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            )
        ]
    }
    
    //    var addCoinAction: CocoaAction {
    //        CocoaAction { _ in
    //            let vc = AddNewWalletVC()
    //            self.present(vc, animated: true, completion: nil)
    //            return .just(())
    //        }
    //    }
}
