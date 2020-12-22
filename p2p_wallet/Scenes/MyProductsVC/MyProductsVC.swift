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
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)

        
        return header
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletsVM
        
        // fix header
        if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: 0)) as? FirstSectionHeaderView
        {
            headerView.setUp(with: viewModel.state.value)
        }
    }
    
    //    var addCoinAction: CocoaAction {
    //        CocoaAction { _ in
    //            let vc = AddNewWalletVC()
    //            self.present(vc, animated: true, completion: nil)
    //            return .just(())
    //        }
    //    }
}
