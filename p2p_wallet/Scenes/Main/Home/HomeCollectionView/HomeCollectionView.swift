//
//  HomeCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import Action

class HomeCollectionView: CollectionView<HomeItem> {
    // MARK: - Constants
    let numberOfWalletsToShow = 4
    
    // MARK: - Actions
//    var openProfileAction: CocoaAction?
//    var receiveAction: CocoaAction?
//    var sendAction: CocoaAction?
//    var swapAction: CocoaAction?
    var showAllProductsAction: CocoaAction?
    var addNewWalletAction: CocoaAction?
    
    var walletCellEditAction: Action<Wallet, Void>?
    
    // MARK: - Lazy actions
    lazy var showHideHiddenWalletsAction = CocoaAction {
        (self.viewModel as! HomeCollectionViewModel).walletsVM.toggleIsHiddenWalletShown()
        return .just(())
    }
    
    // MARK: - Initializers
    init(viewModel: HomeCollectionViewModel) {
        super.init(viewModel: viewModel, sections: [
            CollectionViewSection(
                header: CollectionViewSection.Header(viewClass: ActiveWalletsSectionHeaderView.self, title: ""),
                cellType: HomeWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .absolute(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            ),
            CollectionViewSection(
                header: CollectionViewSection.Header(
                    viewClass: HiddenWalletsSectionHeaderView.self, title: "Hidden wallet"
                ),
                footer: CollectionViewSection.Footer(viewClass: WalletsSectionFooterView.self),
                cellType: HomeWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .absolute(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            )
        ])
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! HomeCollectionViewModel
        
        if let headerView = headerForSection(0) as? ActiveWalletsSectionHeaderView
        {
            headerView.balancesOverviewView.setUp(with: viewModel.walletsVM.state.value)
        }
        
        if let footerView = footerForSection(1) as? WalletsSectionFooterView
        {
            var text = L10n.allMyTokens
            var image = UIImage.indicatorNext
            var action = showAllProductsAction
            switch viewModel.walletsVM.state.value {
            case .loaded(let wallets):
                if wallets.count <= numberOfWalletsToShow {
                    text = L10n.addToken
                    image = .walletAdd
                    action = addNewWalletAction
                }
            default:
                break
            }
            footerView.setUp(title: text, indicator: image, action: action)
        }
    }
    
    // MARK: - Methods
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, CollectionViewItem<HomeItem>> {
        let viewModel = self.viewModel as! HomeCollectionViewModel
        
        // initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<String, CollectionViewItem<HomeItem>>()
        
        // activeWallet
        let activeWalletSections = L10n.wallets
        snapshot.appendSections([activeWalletSections])
        
        var items = viewModel.walletsVM.shownWallets()
            .prefix(numberOfWalletsToShow)
            .map {HomeItem.wallet($0)}
            .map {CollectionViewItem(value: $0)}
        switch viewModel.walletsVM.state.value {
        case .loading:
            items += [
                CollectionViewItem(placeholderIndex: 0),
                CollectionViewItem(placeholderIndex: 1)
            ]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: activeWalletSections)
        
        // hiddenWallet
        let hiddenWalletSections = sections[1].header?.title ?? "Hidden"
        var hiddenItems = [CollectionViewItem<HomeItem>]()
        if viewModel.walletsVM.isHiddenWalletsShown.value {
            hiddenItems = viewModel.walletsVM.hiddenWallets()
                .prefix(numberOfWalletsToShow)
                .map {HomeItem.wallet($0)}
                .map {CollectionViewItem(value: $0)}
        }
        snapshot.appendSections([hiddenWalletSections])
        snapshot.appendItems(hiddenItems, toSection: hiddenWalletSections)
        return snapshot
    }
    
    override func setUpCell(cell: UICollectionViewCell, withItem item: HomeItem?) {
        switch item {
        case .wallet(let wallet):
            (cell as! HomeWalletCell).setUp(with: wallet)
            (cell as! HomeWalletCell).editAction = CocoaAction {
                self.walletCellEditAction?.execute(wallet)
                return .just(())
            }
            (cell as! HomeWalletCell).hideAction = CocoaAction {
                if let wallet = item?.wallet {
                    let walletsVM = (self.viewModel as! HomeCollectionViewModel).walletsVM
                    if wallet.isHidden {
                        walletsVM.unhideWallet(wallet)
                    } else {
                        walletsVM.hideWallet(wallet)
                    }
                }
                return .just(())
            }
        default:
            break
        }
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let viewModel = (self.viewModel as! HomeCollectionViewModel)
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        switch indexPath.section {
        case 0:
            if let view = header as? ActiveWalletsSectionHeaderView {
                view.balancesOverviewView.setUp(with: viewModel.walletsVM.state.value)
                view.showAllBalancesAction = showAllProductsAction
            }
        case 1:
            if let view = header as? HiddenWalletsSectionHeaderView {
                view.showHideHiddenWalletsAction = CocoaAction {
                    viewModel.walletsVM.toggleIsHiddenWalletShown()
                    return .just(())
                }
            }
        default:
            break
        }
        
        return header
    }
    
    override func configureFooterForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let footer = super.configureFooterForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        switch indexPath.section {
        case 1:
            if let view = footer as? WalletsSectionFooterView {
                view.showProductsAction = showAllProductsAction
            }
        default:
            break
        }
        
        return footer
    }
}
