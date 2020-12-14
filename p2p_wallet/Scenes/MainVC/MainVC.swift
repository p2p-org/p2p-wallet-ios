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
    var qrStackView: UIStackView!
    var avatarImageView = UIImageView(width: 44, height: 44, backgroundColor: .c4c4c4, cornerRadius: 22)
    var activeStatusView = UIView(width: 8, height: 8, backgroundColor: .textBlack, cornerRadius: 4)
    var collectionViewHeaderView: FirstSectionHeaderView?
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .vcBackground
        
        // headerView
        configureHeaderView()
        
        // modify collectionView
        collectionView.contentInset = collectionView.contentInset.modifying(dTop: 10+25+10)
    }
    
    override func bind() {
        super.bind()
        collectionView.rx.contentOffset
            .map {$0.y}
            .subscribe(onNext: {y in
                let shouldMinimizeHeader = y > -45
                self.qrStackView.isHidden = shouldMinimizeHeader
                
                let avatarImageViewHeight: CGFloat = shouldMinimizeHeader ? 22: 44
                self.avatarImageView.heightConstraint?.constant = avatarImageViewHeight
                self.avatarImageView.widthConstraint?.constant = avatarImageViewHeight
                self.avatarImageView.layer.cornerRadius = avatarImageViewHeight / 2
                let activeStatusPosition: CGFloat = shouldMinimizeHeader ? 0: 2
                self.activeStatusView.constraint(toRelativeView: self.avatarImageView, withAttribute: .top)?.constant = activeStatusPosition
                self.activeStatusView.constraint(toRelativeView: self.avatarImageView, withAttribute: .trailing)?.constant = -activeStatusPosition
                self.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Binding
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletsVM
        
        // fix header
        collectionViewHeaderView?.setUp(state: viewModel.state.value)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                headerViewClass: FirstSectionHeaderView.self,
                headerTitle: L10n.wallets,
                interGroupSpacing: 16
            ),
            Section(headerTitle: L10n.savings, interGroupSpacing: 16)
        ]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        if indexPath.section == 0,
           let view = header as? FirstSectionHeaderView
        {
            view.receiveAction = self.receiveAction
            view.sendAction = self.sendAction()
            view.swapAction = self.swapAction
            view.addCoinButton.rx.action = self.addCoinAction
            collectionViewHeaderView = view
        }
        
        return header
    }
    
    // MARK: - Delegate
    override func itemDidSelect(_ item: Wallet) {
        show(WalletDetailVC(wallet: item), sender: nil)
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
    
    var receiveAction: CocoaAction {
        CocoaAction { _ in
            let vc = ReceiveTokenVC()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    func sendAction(address: String? = nil) -> CocoaAction {
        CocoaAction { _ in
            let vc = SendTokenVC(wallets: self.viewModel.items, address: address)
            
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
    
    var addCoinAction: CocoaAction {
        CocoaAction { _ in
            let vc = AddNewWalletVC()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    // MARK: - Private
    private func configureHeaderView() {
        let statusBarBgView = UIView(backgroundColor: view.backgroundColor)
        view.addSubview(statusBarBgView)
        statusBarBgView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let headerView = UIView(forAutoLayout: ())
        qrStackView = {
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
        headerView.addSubview(qrStackView)
        qrStackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 16)
        qrStackView.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        headerView.addSubview(avatarImageView)
        avatarImageView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 16), excludingEdge: .leading)
        
        headerView.addSubview(activeStatusView)
        activeStatusView.autoPinEdge(.top, to: .top, of: avatarImageView, withOffset: 2)
        activeStatusView.autoPinEdge(.trailing, to: .trailing, of: avatarImageView, withOffset: -2)
        
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        headerView.autoPinEdge(.top, to: .bottom, of: statusBarBgView)
        
        qrStackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(qrScannerDidSwipe(sender:))))
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
        if indexPath.section == 0
        {
            if elementKind == UICollectionView.elementKindSectionHeader {
                collectionViewHeaderView = nil
            }
        }
    }
}
