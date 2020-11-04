//
//  WalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import DiffableDataSources

class WalletVC: CollectionVC<WalletVC.Section, String, PriceCell> {
    // MARK: - Nested type
    enum Section: String, CaseIterable {
        case wallets
        case savings
        
        var localizedString: String {
            switch self {
            case .wallets:
                return L10n.wallets
            case .savings:
                return L10n.savings
            }
        }
    }
    
    // MARK: - Properties
    let interactor = MenuInteractor()
    
    // MARK: - Subviews
    lazy var qrStackView: UIStackView = {
        let stackView = UIStackView(axis: .horizontal, spacing: 25, alignment: .center, distribution: .fill)
        let imageView = UIImageView(width: 25, height: 25, image: .scanQr)
        imageView.tintColor = UIColor.textBlack.withAlphaComponent(0.5)
         
        stackView.addArrangedSubviews([
            imageView,
            UILabel(text: L10n.slideToScan, textSize: 13, weight: .semibold, textColor: UIColor.textBlack.withAlphaComponent(0.5))
        ])
        stackView.addArrangedSubview(.spacer)
        return stackView
    }()
    var headerView: WCVFirstSectionHeaderView?
    
    init() {
        let viewModel = WalletVM()
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
        let headerView = UIView(backgroundColor: view.backgroundColor)
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        headerView.addSubview(qrStackView)
        qrStackView.autoPinToTopLeftCornerOfSuperviewSafeArea(xInset: 16, yInset: 10)
        qrStackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
        
        qrStackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(qrScannerDidSwipe(sender:))))
        
        // initial snapshot
        var snapshot = DiffableDataSourceSnapshot<Section, String>()
        var items = [String]()
        for i in 0..<5 {
            items.append("\(i)")
        }
        let section = Section.wallets
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
        
        let section2 = Section.savings
        snapshot.appendSections([section2])
        items = []
        for i in 6..<10 {
            items.append("\(i)")
        }
        snapshot.appendItems(items, toSection: section2)
        
        dataSource.apply(snapshot)
    }
    
    override func registerCellAndSupplementaryViews() {
        super.registerCellAndSupplementaryViews()
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeaderView")
        collectionView.register(WCVFirstSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "WCVFirstSectionHeaderView")
    }
    
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
        section?.boundarySupplementaryItems = [sectionHeader]
        return section
    }
    
    override func configureSupplementaryView(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        if indexPath.section == 0 {
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "WCVFirstSectionHeaderView",
                for: indexPath) as? WCVFirstSectionHeaderView
            view?.headerLabel.text = Section.wallets.localizedString
            headerView = view
            return view
        }
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "SectionHeaderView",
            for: indexPath) as? SectionHeaderView
        view?.headerLabel.text = Section.savings.localizedString
        return view
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
            vc.transitioningDelegate = self
            vc.modalPresentationStyle = .custom
            self.present(vc, animated: true, completion: nil)
        }
    }
}

extension WalletVC: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        PresentMenuAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DismissMenuAnimator()
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

extension WalletVC: TabBarItemVC {
    var scrollView: UIScrollView {collectionView}
}

extension WalletVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionHeader,
           indexPath.section == 0
        {
            headerView = nil
        }
    }
}
