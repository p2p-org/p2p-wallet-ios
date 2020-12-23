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
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    override var preferredStatusBarStyle: UIStatusBarStyle {.lightContent}
    
    var walletsVM: WalletsVM {(viewModel as! MainVM).walletsVM}
    
    var qrStackView: UIStackView!
    lazy var avatarImageView = UIImageView(width: 32, height: 32, backgroundColor: .c4c4c4, cornerRadius: 16)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    lazy var activeStatusView = UIView(width: 8, height: 8, backgroundColor: .red, cornerRadius: 4)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    
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
        view.backgroundColor = .h1b1b1b
        setStatusBarColor(.h1b1b1b)
        
        // configure header
        let headerView = UIView(forAutoLayout: ())
        view.addSubview(headerView)
        headerView.autoPinEdge(toSuperviewEdge: .leading)
        headerView.autoPinEdge(toSuperviewEdge: .trailing)
        headerView.autoPinEdge(toSuperviewSafeArea: .top)
        headerView.row([
            UIImageView(width: 25, height: 25, image: .scanQr, tintColor: UIColor.white.withAlphaComponent(0.35)),
            {
                let view = UIView(forAutoLayout: ())
                view.addSubview(avatarImageView)
                avatarImageView.autoPinEdgesToSuperviewEdges(with: .zero)
                view.addSubview(activeStatusView)
                activeStatusView.autoPinEdge(.top, to: .top, of: avatarImageView)
                activeStatusView.autoPinEdge(.trailing, to: .trailing, of: avatarImageView)
                return view
            }()
        ], padding: .init(x: .defaultPadding, y: 10))
        
        // rearrange collectionView
        collectionView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        collectionView.autoPinEdge(.top, to: .bottom, of: headerView)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(viewClass: FirstSectionHeaderView.self, title: ""),
                footer: Section.Footer(viewClass: FirstSectionFooterView.self),
                cellType: MainWalletCell.self,
                interGroupSpacing: 30,
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
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
//        let section2 = L10n.friends
//        snapshot.appendSections([section2])
////        snapshot.appendItems([MainVCItem.friend], toSection: section2)
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
                view.setUp(with: walletsVM.state.value)
            }
        default:
            break
        }
        
        return header
    }
    
    override func configureFooterForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let footer = super.configureFooterForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        switch indexPath.section {
        case 0:
            if let view = footer as? FirstSectionFooterView {
                view.showProductsAction = self.showAllProducts
            }
        default:
            break
        }
        
        return footer
    }
    
    // MARK: - Actions
    override func dataDidLoad() {
        super.dataDidLoad()
        
        if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: 0)) as? FirstSectionHeaderView
        {
            headerView.setUp(with: walletsVM.state.value)
        }
    }
    
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
    
    var showAllProducts: CocoaAction {
        CocoaAction { _ in
            self.present(MyProductsVC(), animated: true, completion: nil)
            return .just(())
        }
    }
    
    var openProfile: CocoaAction {
        CocoaAction { _ in
            self.present(ProfileVC(), animated: true, completion: nil)
            return .just(())
        }
    }
    
    @objc func avatarImageViewDidTouch() {
        present(ProfileVC(), animated: true, completion: nil)
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
