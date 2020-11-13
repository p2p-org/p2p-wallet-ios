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

class WalletVC: CollectionVC<SolanaSDK.Token, TokenCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    // MARK: - Properties
    let interactor = MenuInteractor()
    override var sectionHeaders: [SectionHeader] {
        [
            SectionHeader(headerTitle: L10n.wallets),
            SectionHeader(headerTitle: L10n.savings)
        ]
    }
    
    // MARK: - Subviews
    lazy var qrStackView: UIStackView = {
        let stackView = UIStackView(axis: .horizontal, spacing: 25, alignment: .center, distribution: .fill)
        let imageView = UIImageView(width: 25, height: 25, image: .scanQr)
        imageView.tintColor = .secondary
         
        stackView.addArrangedSubviews([
            imageView,
            UILabel(text: L10n.slideToScan, textSize: 13, weight: .semibold, textColor: .secondary)
        ])
        stackView.addArrangedSubview(.spacer)
        return stackView
    }()
    var headerView: WCVFirstSectionHeaderView?
    
    init() {
        let viewModel = WalletVM.ofCurrentUser
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        
        // modify collectionView
        collectionView.contentInset = collectionView.contentInset.modifying(dTop: 10+25+10)
        collectionView.delegate = self
        
        // header view
        let statusBarBgView = UIView(backgroundColor: view.backgroundColor)
        view.addSubview(statusBarBgView)
        statusBarBgView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let qrView = UIView(backgroundColor: view.backgroundColor)
        qrView.addSubview(qrStackView)
        qrStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(x: 16, y: 10))
        
        view.addSubview(qrView)
        qrView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        qrView.autoPinEdge(.top, to: .bottom, of: statusBarBgView)
        
        qrStackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(qrScannerDidSwipe(sender:))))
    }
    
    override func registerCellAndSupplementaryViews() {
        super.registerCellAndSupplementaryViews()
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderView")
        collectionView.register(WCVFirstSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "WCVFirstSectionHeaderView")
        collectionView.register(WCVFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "WCVFooterView")
        collectionView.register(EmptySectionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "EmptySectionFooterView")
    }
    
    // MARK: - Binding
    override var combinedObservable: Observable<Void> {
        let viewModel = self.viewModel as! WalletVM
        return Observable.combineLatest(
            viewModel.state,
            viewModel.balanceVM.state
        )
        .map {_ in ()}
    }
    
    override func mapDataToSnapshot() -> DiffableDataSourceSnapshot<String, SolanaSDK.Token> {
        var snapshot = DiffableDataSourceSnapshot<String, SolanaSDK.Token>()
        let section = L10n.wallets
        snapshot.appendSections([section])
        let items = viewModel.items.value
        snapshot.appendItems(items, toSection: section)
        return snapshot
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletVM
        
        // fix header
        headerView?.setUp(balanceVM: viewModel.balanceVM)
    }
    
    // MARK: - Layout
    override func createLayoutForSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let section = super.createLayoutForSection(sectionIndex, environment: env)
        section?.interGroupSpacing = 16
        
        // Header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
        
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        
        section?.boundarySupplementaryItems = [sectionHeader, sectionFooter]
        return section
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        if indexPath.section == 0 {
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: "WCVFirstSectionHeaderView",
                for: indexPath) as? WCVFirstSectionHeaderView
            view?.setUp(headerTitle: L10n.wallets)
            view?.receiveAction = self.receiveAction
            view?.sendAction = self.sendAction
            headerView = view
            return view
        }
        return super.configureFooterForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
    }
    
    override func configureFooterForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        if indexPath.section == 0 {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "WCVFooterView", for: indexPath) as? WCVFooterView
            return view
        } else {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "EmptySectionFooterView", for: indexPath) as? EmptySectionFooterView
            return view
        }
    }
    
    // MARK: - Actions
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
            vc.transitioningDelegate = self
            vc.modalPresentationStyle = .custom
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    var receiveAction: CocoaAction {
        CocoaAction { _ in
            let vc = ReceiveTokenVC()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    var sendAction: CocoaAction {
        CocoaAction { _ in
            let vc = SendTokenVC()
            self.show(vc, sender: nil)
            return .just(())
        }
    }
}

extension WalletVC: UIViewControllerTransitioningDelegate {
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

extension WalletVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionHeader,
           indexPath.section == 0
        {
            headerView = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        show(CoinDetailVC(), sender: nil)
    }
}
