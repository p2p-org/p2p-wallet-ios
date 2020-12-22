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

enum MainVCItem: ListItemType {
    static func placeholder(at index: Int) -> MainVCItem {
        .wallet(Wallet.placeholder(at: index))
    }
    
    var id: String {
        switch self {
        case .wallet(let wallet):
            return "wallet#\(wallet.id)"
        case .friend:
            return "friend"
        }
    }
    case wallet(Wallet)
    case friend // TODO: - Friend
}

class MainVC: CollectionVC<MainVCItem> {
    override var preferredStatusBarStyle: UIStatusBarStyle {.lightContent}
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    var walletsVM: WalletsVM {(viewModel as! MainVM).walletsVM}
    
    init() {
        let vm = MainVM()
        super.init(viewModel: vm)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .white
        setStatusBarColor(.h1b1b1b)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(viewClass: FirstSectionHeaderView.self, title: ""),
                footer: Section.Footer(viewClass: FirstSectionFooterView.self),
                cellType: MainWalletCell.self,
                interGroupSpacing: 30,
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16),
                background: FirstSectionBackgroundView.self
            ),
            Section(
                header: Section.Header(viewClass: SecondSectionHeaderView.self, title: ""),
                cellType: FriendCell.self,
                background: SecondSectionBackgroundView.self
            )
        ]
    }
    
    override func mapDataToSnapshot() -> DiffableDataSourceSnapshot<String, MainVCItem> {
        // initial snapshot
        var snapshot = DiffableDataSourceSnapshot<String, MainVCItem>()
        
        // section 1
        let section = L10n.wallets
        snapshot.appendSections([section])
        
        var items = filterWallet(self.walletsVM.items).map {MainVCItem.wallet($0)}
        switch walletsVM.state.value {
        case .loading:
            items += [MainVCItem.placeholder(at: 0), MainVCItem.placeholder(at: 1)]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: section)
        
        // section 2
        let section2 = L10n.friends
        snapshot.appendSections([section2])
//        snapshot.appendItems([MainVCItem.friend], toSection: section2)
        return snapshot
    }
    
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: MainVCItem) -> UICollectionViewCell {
        switch item {
        case .wallet(let wallet):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MainWalletCell.self), for: indexPath) as? MainWalletCell
            cell?.setUp(with: wallet)
            if item.id.starts(with: "wallet#placeholder") {
                cell?.showLoading()
            } else {
                cell?.hideLoading()
            }
            return cell ?? UICollectionViewCell()
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FriendCell.self), for: indexPath)
            return cell
        }
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        switch indexPath.section {
        case 0:
            if let view = header as? FirstSectionHeaderView {
                view.openProfileAction = self.openProfile
            }
        case 1:
            if let view = header as? SecondSectionHeaderView {
                view.receiveAction = self.receiveAction
                view.sendAction = self.sendAction()
                view.exchangeAction = self.swapAction
            }
        default:
            break
        }
        
        return header
    }
    
    // MARK: - Actions
    override func itemDidSelect(_ item: MainVCItem) {
        switch item {
        case .wallet(let wallet):
            present(WalletDetailVC(wallet: wallet), animated: true, completion: nil)
        default:
            break
        }
    }
    
    var receiveAction: CocoaAction {
        CocoaAction { _ in
            let wallets = self.walletsVM.items
            if wallets.count == 0 {return .just(())}
            let vc = ReceiveTokenVC(wallets: wallets)
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    func sendAction(address: String? = nil) -> CocoaAction {
        CocoaAction { _ in
            let wallets = self.walletsVM.items
            if wallets.count == 0 {return .just(())}
            let vc = SendTokenVC(wallets: wallets, address: address)
            self.show(vc, sender: nil)
            return .just(())
        }
    }
    
    var swapAction: CocoaAction {
        CocoaAction { _ in
            let wallets = self.walletsVM.items
            if wallets.count == 0 {return .just(())}
            let vc = SwapTokenVC(wallets: wallets)
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
    
    var openProfile: CocoaAction {
        CocoaAction { _ in
            self.present(ProfileVC(), animated: true, completion: nil)
            return .just(())
        }
    }
    
    // MARK: - Helpers
    func filterWallet(_ items: [Wallet]) -> [Wallet] {
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
}
