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
    override var preferredStatusBarStyle: UIStatusBarStyle {.lightContent}
    
    // MARK: - Properties
    let interactor = MenuInteractor()
    var walletsVM: WalletsVM {(viewModel as! MainVM).walletsVM}
    
    lazy var avatarImageView = UIImageView(width: 32, height: 32, backgroundColor: .c4c4c4, cornerRadius: 16)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    lazy var activeStatusView = UIView(width: 8, height: 8, backgroundColor: .red, cornerRadius: 4)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    
    lazy var tabBar = TabBar(cornerRadius: .defaultPadding, contentInset: UIEdgeInsets(x: 0, y: .defaultPadding))
    
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
            {
                let qrScannerView = UIImageView(width: 25, height: 25, image: .scanQr, tintColor: UIColor.white.withAlphaComponent(0.35)
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
        
        refreshControl.tintColor = .white
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
            headerView.balancesOverviewView.setUp(with: walletsVM.state.value)
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
                .prefix(3)
        )
        
        return wallets
    }
    
    private func createButton(image: UIImage, title: String) -> UIStackView {
        let button = UIButton(width: 56, height: 56, backgroundColor: .f4f4f4, cornerRadius: 12, label: title, contentInsets: .init(all: 16))
        button.setImage(image, for: .normal)
        button.isUserInteractionEnabled = false
        button.tintColor = .textBlack
        return UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill, arrangedSubviews: [
            button,
            UILabel(text: title, textSize: 12)
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
