//
//  WalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import Action
import RxSwift

enum MainVCItem: ListItemType {
    static func placeholder(at index: Int) -> MainVCItem {
        .wallet(Wallet.placeholder(at: index))
    }
    
    var id: String {
        switch self {
        case .wallet(let wallet):
            return "\(wallet.id)#wallet"
        case .friend:
            return "friend"
        }
    }
    case wallet(Wallet)
    case friend // TODO: - Friend
}

class MainVC: CollectionVC<MainVCItem> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    // MARK: - Properties
    let interactor = MenuInteractor()
    var walletsVM: WalletsVM {WalletsVM.ofCurrentUser}
    let numberOfWalletsToShow = 4
    
    lazy var avatarImageView = UIImageView(width: 32, height: 32, backgroundColor: .c4c4c4, cornerRadius: 16)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    lazy var activeStatusView = UIView(width: 8, height: 8, backgroundColor: .red, cornerRadius: 4)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    
    lazy var tabBar: TabBar = {
        let tabBar = TabBar(cornerRadius: .defaultPadding, contentInset: UIEdgeInsets(top: 20, left: 0, bottom: 8, right: 0))
        tabBar.backgroundColor = .background2
        return tabBar
    }()
    
    init() {
        let vm = MainVM()
        super.init(viewModel: vm)
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .background
        setStatusBarColor(view.backgroundColor!)
        
        // configure header
        let headerView = UIView(forAutoLayout: ())
        view.addSubview(headerView)
        headerView.autoPinEdge(toSuperviewEdge: .leading)
        headerView.autoPinEdge(toSuperviewEdge: .trailing)
        headerView.autoPinEdge(toSuperviewSafeArea: .top)
        headerView.row([
            {
                let qrScannerView = UIImageView(width: 25, height: 25, image: .scanQr, tintColor: .textSecondary
                )
                    .onTap(self, action: #selector(qrScannerDidTouch))
                qrScannerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(qrScannerDidSwipe(sender:))))
                return qrScannerView
            }(),
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
        
        // tabBar
        view.addSubview(tabBar)
        tabBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        tabBar.stackView.addArrangedSubviews([
            .spacer,
//                    createButton(image: .walletAdd, title: L10n.buy),
            createButton(image: .walletReceive, title: L10n.receive)
                .onTap(self, action: #selector(buttonReceiveDidTouch)),
            createButton(image: .walletSend, title: L10n.send)
                .onTap(self, action: #selector(buttonSendDidTouch)),
            createButton(image: .walletSwap, title: L10n.exchange)
                .onTap(self, action: #selector(buttonExchangeDidTouch)),
            .spacer
        ])
        
        // rearrange collectionView
        collectionView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        collectionView.autoPinEdge(.top, to: .bottom, of: headerView)
        
        collectionView.constraintToSuperviewWithAttribute(.bottom)?.isActive = false
        collectionView.autoPinEdge(.bottom, to: .top, of: tabBar, withOffset: .defaultPadding)
        
        collectionView.contentInset.modify(dBottom: .defaultPadding)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(viewClass: FirstSectionHeaderView.self, title: ""),
                footer: Section.Footer(viewClass: FirstSectionFooterView.self),
                cellType: MainWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .estimated(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            )
        ]
    }
    
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, MainVCItem> {
        // initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<String, MainVCItem>()
        
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
        return snapshot
    }
    
    override func setUpCell(cell: UICollectionViewCell, withItem item: MainVCItem) {
        switch item {
        case .wallet(let wallet):
            (cell as! MainWalletCell).setUp(with: wallet)
        case .friend:
            break
        }
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        switch indexPath.section {
        case 0:
            if let view = header as? FirstSectionHeaderView {
                view.balancesOverviewView.setUp(with: walletsVM.state.value)
                view.showAllBalancesAction = self.showAllProducts
            }
        default:
            break
        }
        
        return header
    }
    
    // MARK: - Actions
    override func dataDidLoad() {
        super.dataDidLoad()
        
        if let headerView = headerForSection(0) as? FirstSectionHeaderView
        {
            headerView.balancesOverviewView.setUp(with: walletsVM.state.value)
        }
        
        if let footerView = footerForSection(0) as? FirstSectionFooterView
        {
            var text = L10n.allMyTokens
            var image = UIImage.indicatorNext
            var action = showAllProducts
            switch walletsVM.state.value {
            case .loaded(let wallets):
                if wallets.count <= numberOfWalletsToShow {
                    text = L10n.addToken
                    image = .walletAdd
                    action = addCoin
                }
            default:
                break
            }
            footerView.setUp(title: text, indicator: image, action: action)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.tabBar.alpha = self.walletsVM.data.isEmpty ? 0 : 1
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
            let vm = _SendTokenViewModel(wallets: wallets, activeWallet: nil)
            let vc = SendTokenViewController(viewModel: vm)
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    var swapAction: CocoaAction {
        CocoaAction { _ in
            let wallets = self.walletsVM.items
            if wallets.count == 0 {return .just(())}
            let vc = SwapTokenVC()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    var showAllProducts: CocoaAction {
        CocoaAction { _ in
            self.present(MyProductsVC(), animated: true, completion: nil)
            return .just(())
        }
    }
    
    var addCoin: CocoaAction {
        CocoaAction {_ in
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
    
    @objc func avatarImageViewDidTouch() {
        present(ProfileVC(), animated: true, completion: nil)
    }
    
    @objc func buttonReceiveDidTouch() {
        receiveAction.execute()
    }
    
    @objc func buttonSendDidTouch() {
        sendAction().execute()
    }
    
    @objc func buttonExchangeDidTouch() {
        swapAction.execute()
    }
    
    @objc func qrScannerDidSwipe(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let progress = MenuHelper.calculateProgress(translationInView: translation, viewBounds: view.bounds, direction: .right
        )
        MenuHelper.mapGestureStateToInteractor(
            gestureState: sender.state,
            progress: progress,
            interactor: interactor)
        {
            let vc = QrCodeScannerVC()
            vc.callback = { code in
                if NSRegularExpression.publicKey.matches(code) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.sendAction(address: code).execute()
                    }
                    return true
                }
                return false
            }
            vc.transitioningDelegate = self
            vc.modalPresentationStyle = .custom
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func qrScannerDidTouch() {
        let vc = QrCodeScannerVC()
        vc.callback = { code in
            if NSRegularExpression.publicKey.matches(code) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.sendAction(address: code).execute()
                }
                return true
            }
            return false
        }
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
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
                .prefix(numberOfWalletsToShow - 1)
        )
        
        return wallets
    }
    
    private func createButton(image: UIImage, title: String) -> UIStackView {
        let button = UIButton(width: 56, height: 56, backgroundColor: .h5887ff, cornerRadius: 12, label: title, contentInsets: .init(all: 16))
        button.setImage(image, for: .normal)
        button.isUserInteractionEnabled = false
        button.tintColor = .white
        return UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill, arrangedSubviews: [
            button,
            UILabel(text: title, textSize: 12, textColor: .textSecondary)
        ])
    }
}

extension MainVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        PresentMenuAnimator()
    }
    
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        DismissMenuAnimator()
//    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
