//
//  WalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import Action
import RxSwift

protocol MainScenesFactory {
    func makeWalletDetailVC(wallet: Wallet) -> WalletDetailVC
    func makeReceiveTokenViewController() -> ReceiveTokenVC
    func makeSendTokenViewController(activeWallet: Wallet?, destinationAddress: String?) -> WLModalWrapperVC
    func makeSwapTokenViewController(fromWallet wallet: Wallet?) -> SwapTokenViewController
    func makeMyProductsVC() -> MyProductsVC
    func makeProfileVC() -> ProfileVC
    func makeAddNewTokenVC() -> AddNewWalletVC
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
}

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
    
    var wallet: Wallet? {
        switch self {
        case .wallet(let wallet):
            return wallet
        default:
            break
        }
        return nil
    }
}

class MainVC: CollectionVC<MainVCItem> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}

    // MARK: - Properties
    let interactor = MenuInteractor()
    let numberOfWalletsToShow = 4
    let scenesFactory: MainScenesFactory
    
    init(viewModel: ListViewModel<MainVCItem>, scenesFactory: MainScenesFactory) {
        self.scenesFactory = scenesFactory
        super.init(viewModel: viewModel)
    }
    
    lazy var avatarImageView = UIImageView(width: 30, height: 30, image: .mainSettings)
        .onTap(self, action: #selector(avatarImageViewDidTouch))
    
    lazy var tabBar: TabBar = {
        let tabBar = TabBar(cornerRadius: .defaultPadding, contentInset: UIEdgeInsets(top: 20, left: 0, bottom: 8, right: 0))
        tabBar.backgroundColor = .background2
        return tabBar
    }()
    
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
            avatarImageView
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(collectionViewDidTouch(_:)))
        collectionView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Layout
    override var sections: [CollectionViewSection] {
        [
            CollectionViewSection(
                header: CollectionViewSection.Header(viewClass: ActiveWalletsSectionHeaderView.self, title: ""),
                cellType: MainWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .absolute(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            ),
            CollectionViewSection(
                header: CollectionViewSection.Header(
                    viewClass: HiddenWalletsSectionHeaderView.self, title: "Hidden wallet"
                ),
                footer: CollectionViewSection.Footer(viewClass: WalletsSectionFooterView.self),
                cellType: MainWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .absolute(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            )
        ]
    }
    
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, MainVCItem> {
        let viewModel = self.viewModel as! MainVM
        
        // initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<String, MainVCItem>()
        
        // activeWallet
        let activeWalletSections = L10n.wallets
        snapshot.appendSections([activeWalletSections])
        
        var items = viewModel.walletsVM.shownWallets()
            .prefix(numberOfWalletsToShow)
            .map {MainVCItem.wallet($0)}
        switch viewModel.walletsVM.state.value {
        case .loading:
            items += [MainVCItem.placeholder(at: 0), MainVCItem.placeholder(at: 1)]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: activeWalletSections)
        
        // hiddenWallet
        let hiddenWalletSections = sections[1].header?.title ?? "Hidden"
        var hiddenItems = [MainVCItem]()
        if viewModel.walletsVM.isHiddenWalletsShown.value {
            hiddenItems = viewModel.walletsVM.hiddenWallets()
                .prefix(numberOfWalletsToShow)
                .map {MainVCItem.wallet($0)}
        }
        snapshot.appendSections([hiddenWalletSections])
        snapshot.appendItems(hiddenItems, toSection: hiddenWalletSections)
        return snapshot
    }
    
    override func setUpCell(cell: UICollectionViewCell, withItem item: MainVCItem) {
        switch item {
        case .wallet(let wallet):
            (cell as! MainWalletCell).setUp(with: wallet)
            (cell as! MainWalletCell).editAction = CocoaAction {
                guard let pubkey = wallet.pubkey else {return .just(())}
                let vc = self.scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
                self.present(vc, animated: true, completion: nil)
                return .just(())
            }
            (cell as! MainWalletCell).hideAction = CocoaAction {
                if let wallet = item.wallet {
                    let walletsVM = (self.viewModel as? MainVM)?.walletsVM
                    if wallet.isHidden {
                        walletsVM?.unhideWallet(wallet)
                    } else {
                        walletsVM?.hideWallet(wallet)
                    }
                }
                return .just(())
            }
        case .friend:
            break
        }
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let viewModel = self.viewModel as! MainVM
        
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        switch indexPath.section {
        case 0:
            if let view = header as? ActiveWalletsSectionHeaderView {
                view.balancesOverviewView.setUp(with: viewModel.walletsVM.state.value)
                view.showAllBalancesAction = self.showAllProducts
            }
        case 1:
            if let view = header as? HiddenWalletsSectionHeaderView {
                view.showHideHiddenWalletsAction = CocoaAction {
                    (self.viewModel as! MainVM).walletsVM.toggleIsHiddenWalletShown()
                    return .just(())
                }
            }
        default:
            break
        }
        
        return header
    }
    
    // MARK: - Actions
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! MainVM
        
        if let headerView = headerForSection(0) as? ActiveWalletsSectionHeaderView
        {
            headerView.balancesOverviewView.setUp(with: viewModel.walletsVM.state.value)
        }
        
        if let footerView = footerForSection(1) as? WalletsSectionFooterView
        {
            var text = L10n.allMyTokens
            var image = UIImage.indicatorNext
            var action = showAllProducts
            switch viewModel.walletsVM.state.value {
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
            self.tabBar.alpha = viewModel.walletsVM.data.isEmpty ? 0 : 1
        }
    }
    
    override func itemDidSelect(_ item: MainVCItem) {
        switch item {
        case .wallet(let wallet):
            let vc = scenesFactory.makeWalletDetailVC(wallet: wallet)
            present(vc, animated: true, completion: nil)
        default:
            break
        }
    }
    
    var receiveAction: CocoaAction {
        CocoaAction { _ in
            let vc = self.scenesFactory.makeReceiveTokenViewController()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    func sendAction(address: String? = nil) -> CocoaAction {
        CocoaAction { _ in
            let vc = self.scenesFactory
                .makeSendTokenViewController(activeWallet: nil, destinationAddress: address)
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    var swapAction: CocoaAction {
        CocoaAction { _ in
            let vc = self.scenesFactory.makeSwapTokenViewController(fromWallet: nil)
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    var showAllProducts: CocoaAction {
        CocoaAction { _ in
            let vc = self.scenesFactory.makeMyProductsVC()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    var addCoin: CocoaAction {
        CocoaAction {_ in
            let vc = self.scenesFactory.makeAddNewTokenVC()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    var openProfile: CocoaAction {
        CocoaAction { _ in
            let profileVC = self.scenesFactory.makeProfileVC()
            self.present(profileVC, animated: true, completion: nil)
            return .just(())
        }
    }
    
    @objc func avatarImageViewDidTouch() {
        let vc = self.scenesFactory.makeProfileVC()
        present(vc, animated: true, completion: nil)
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
    override func itemAtIndexPath(_ indexPath: IndexPath) -> MainVCItem? {
        let viewModel = (self.viewModel as? MainVM)
        switch indexPath.section {
        case 0:
            if let wallet = viewModel?.walletsVM.shownWallets()[indexPath.row]
            {
                return MainVCItem.wallet(wallet)
            }
        case 1:
            if let wallet = viewModel?.walletsVM.hiddenWallets()[indexPath.row]
            {
                return MainVCItem.wallet(wallet)
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
