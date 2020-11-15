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
    
    // MARK: - Binding
    override var combinedObservable: Observable<Void> {
        let viewModel = self.viewModel as! WalletVM
        return Observable.combineLatest(
            viewModel.state,
            viewModel.balanceVM.state
        )
        .map {_ in ()}
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletVM
        
        // fix header
        headerView?.setUp(balanceVM: viewModel.balanceVM)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                headerViewClass: WCVFirstSectionHeaderView.self,
                headerTitle: L10n.wallets,
                footerViewClass: WCVFooterView.self,
                footerLayout: {
                    let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
                    return NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
                }()
            ),
            Section(headerTitle: L10n.savings)
        ]
    }
    
    override func createLayoutForSection(_ sectionIndex: Int, environment env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let section = super.createLayoutForSection(sectionIndex, environment: env)
        section?.interGroupSpacing = 16
        return section
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        if indexPath.section == 0,
           let view = header as? WCVFirstSectionHeaderView
        {
            view.receiveAction = self.receiveAction
            view.sendAction = self.sendAction
            headerView = view
        }
        
        return header
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
