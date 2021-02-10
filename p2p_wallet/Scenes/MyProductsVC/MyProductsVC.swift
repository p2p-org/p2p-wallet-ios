//
//  MyProductsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation

class MyProductsVC: WLModalWrapperVC {
    override var padding: UIEdgeInsets {.init(x: 0, y: .defaultPadding)}
    init() {
        super.init(wrapped: _MyProductsVC())
    }
    
    override func setUp() {
        super.setUp()
        stackView.axis = .horizontal
        stackView.addArrangedSubviews([
            UILabel(text: L10n.allMyTokens, textSize: 21, weight: .semibold)
                .padding(.init(x: 20, y: 0)),
            UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .h5887ff)
                .padding(.init(all: 10), backgroundColor: .eff3ff, cornerRadius: 12)
                .padding(.init(x: 20, y: 0))
                .onTap(self, action: #selector(buttonAddCoinDidTouch))
        ])
    }
    
    @objc func buttonAddCoinDidTouch() {
        let vc = AddNewWalletVC()
        self.present(vc, animated: true, completion: nil)
    }
}

class _MyProductsVC: MyWalletsVC {
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(viewClass: FirstSectionHeaderView.self, title: L10n.balances, titleFont: .systemFont(ofSize: 17, weight: .semibold)),
                cellType: MyProductsWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .estimated(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            )
        ]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        switch indexPath.section {
        case 0:
            if let view = header as? FirstSectionHeaderView {
                view.balancesOverviewView.setUp(with: viewModel.state.value)
            }
        default:
            break
        }
        return header
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletsVM
        
        // fix header
        if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: 0)) as? FirstSectionHeaderView
        {
            headerView.balancesOverviewView.setUp(with: viewModel.state.value)
        }
    }
}
