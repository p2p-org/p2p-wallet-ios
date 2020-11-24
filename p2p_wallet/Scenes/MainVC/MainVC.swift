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

class MainVC: MyWalletsVC<MainWalletCell> {
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
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        
        // modify collectionView
        collectionView.contentInset = collectionView.contentInset.modifying(dTop: 10+25+10)
        
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
        
        // FIXME: - Show qrView later
        qrView.isHidden = true
    }
    
    // MARK: - Binding
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletsVM
        
        // fix header
        headerView?.setUp(state: viewModel.state.value)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                headerViewClass: WCVFirstSectionHeaderView.self,
                headerTitle: L10n.wallets,
                footerViewClass: WCVFooterView.self,
                interGroupSpacing: 16
            ),
            Section(headerTitle: L10n.savings, interGroupSpacing: 16)
        ]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        if indexPath.section == 0,
           let view = header as? WCVFirstSectionHeaderView
        {
            view.receiveAction = self.receiveAction
            view.sendAction = self.sendAction
            view.swapAction = self.swapAction
            headerView = view
        }
        
        return header
    }
    
    // MARK: - Delegate
    override func itemDidSelect(_ item: Wallet) {
        show(CoinDetailVC(), sender: nil)
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
            let vc = SendTokenVC(wallets: self.viewModel.items)
            self.show(vc, sender: nil)
            return .just(())
        }
    }
    
    var swapAction: CocoaAction {
        CocoaAction { _ in
            let vc = SwapTokenVC(wallets: self.viewModel.items)
            self.show(vc, sender: nil)
            return .just(())
        }
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

extension MainVC {
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionHeader,
           indexPath.section == 0
        {
            headerView = nil
        }
    }
}
