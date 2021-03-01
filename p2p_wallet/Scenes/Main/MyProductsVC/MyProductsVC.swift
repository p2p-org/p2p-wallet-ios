//
//  MyProductsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation

class MyProductsVC: WLModalWrapperVC {
    override var padding: UIEdgeInsets {.init(x: 0, y: .defaultPadding)}
    
    let scenesFactory: MyWalletsScenesFactory
    init(walletsVM: WalletsVM, scenesFactory: MyWalletsScenesFactory) {
        self.scenesFactory = scenesFactory
        super.init(wrapped: _MyProductsVC(viewModel: walletsVM, sceneFactory: scenesFactory))
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
        let vc = scenesFactory.makeAddNewTokenVC()
        self.present(vc, animated: true, completion: nil)
    }
}

class _MyProductsVC: MyWalletsVC {
    
    override func setUp() {
        super.setUp()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(collectionViewDidTouch(_:)))
        collectionView.addGestureRecognizer(tapGesture)
    }
    
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, Wallet> {
        let viewModel = (self.viewModel as! WalletsVM)
        // initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<String, Wallet>()
        
        // activeWallet
        let activeWalletSections = L10n.wallets
        snapshot.appendSections([activeWalletSections])
        
        var items = viewModel.shownWallets()
        switch viewModel.state.value {
        case .loading:
            items += [Wallet.placeholder(at: 0), Wallet.placeholder(at: 1)]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: activeWalletSections)
        
        // hiddenWallet
        let hiddenWalletSections = sections[1].header?.title ?? "Hidden"
        var hiddenItems = [Wallet]()
//        if viewModel.isHiddenWalletsShown.value {
            hiddenItems = viewModel.hiddenWallets()
//        }
        snapshot.appendSections([hiddenWalletSections])
        snapshot.appendItems(hiddenItems, toSection: hiddenWalletSections)
        return snapshot
    }
    
    override var sections: [CollectionViewSection] {
        [
            CollectionViewSection(
                header: CollectionViewSection.Header(viewClass: FirstSectionHeaderView.self, title: L10n.balances, titleFont: .systemFont(ofSize: 17, weight: .semibold)),
                cellType: MainWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .estimated(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            ),
            CollectionViewSection(
                header: CollectionViewSection.Header(
                    viewClass: HiddenWalletsSectionHeaderView.self, title: "Hidden wallet"
                ),
                cellType: MainWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .absolute(45),
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
    
    override func itemAtIndexPath(_ indexPath: IndexPath) -> Wallet? {
        let viewModel = (self.viewModel as? WalletsVM)
        switch indexPath.section {
        case 0:
            if let wallet = viewModel?.shownWallets()[indexPath.row]
            {
                return wallet
            }
        case 1:
            if let wallet = viewModel?.hiddenWallets()[indexPath.row]
            {
                return wallet
            }
        default:
            break
        }
        return nil
    }
    
    @objc func collectionViewDidTouch(_ sender: UIGestureRecognizer) {
        if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
            if let item = itemAtIndexPath(indexPath) {
                itemDidSelect(item)
            }
        } else {
            print("collection view was tapped")
        }
    }
}
