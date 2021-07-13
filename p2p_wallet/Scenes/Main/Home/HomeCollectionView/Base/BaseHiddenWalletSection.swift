//
//  BaseHiddenWalletSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/03/2021.
//

import Foundation
import BECollectionView
import Action

class HiddenWalletsSectionHeaderView: BaseCollectionReusableView {
    // MARK: - Properties
    var showHideHiddenWalletsAction: CocoaAction?
    
    // MARK: - Subviews
    private lazy var imageView = UIImageView(width: 20, height: 20, image: .visibilityShow, tintColor: .textSecondary)
    private lazy var headerLabel = UILabel(text: "Wallets", textSize: 15)
    private lazy var imageViewWrapper = imageView
        .padding(.init(all: 12.5))
        .padding(.init(top: 30, left: .defaultPadding, bottom: 30, right: 0))
    
    override func commonInit() {
        super.commonInit()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 16
        
        stackView.addArrangedSubviews([
            imageViewWrapper,
            headerLabel
        ])
        
        stackView.isUserInteractionEnabled = true
        stackView.onTap(self, action: #selector(stackViewDidTouch))
    }
    
    @discardableResult
    func setUp(isHiddenWalletsShown: Bool, hiddenWalletList: [Wallet]) -> Bool {
        let isSubviewsHidden = imageViewWrapper.isHidden
        if isHiddenWalletsShown {
            imageView.tintColor = .textBlack
            imageView.image = .visibilityHide
            headerLabel.textColor = .textBlack
            headerLabel.text = L10n.hide
        } else {
            imageView.tintColor = .textSecondary
            imageView.image = .visibilityShow
            headerLabel.textColor = .textSecondary
            headerLabel.text = L10n.dHiddenWallet(hiddenWalletList.count)
        }
        
        imageViewWrapper.isHidden = hiddenWalletList.isEmpty
        headerLabel.isHidden = hiddenWalletList.isEmpty
        
        // return true if should update height, else return false
        if imageViewWrapper.isHidden != isSubviewsHidden {
            return true
        }
        return false
    }
    
    @objc func stackViewDidTouch() {
        showHideHiddenWalletsAction?.execute()
    }
}

class HiddenWalletsSection: WalletsSection {
    var showHideHiddenWalletsAction: CocoaAction?
    
    init(
        index: Int,
        viewModel: WalletsRepository,
        header: BECollectionViewSectionHeaderLayout = .init(
            viewClass: HiddenWalletsSectionHeaderView.self
        ),
        footer: BECollectionViewSectionFooterLayout? = nil,
        background: UICollectionReusableView.Type? = nil,
        limit: Int? = nil
    ) {
        super.init(
            index: index,
            viewModel: viewModel,
            header: header,
            footer: footer,
            background: background,
            cellType: HomeWalletCell.self,
            customFilter: { item in
                guard let wallet = item as? Wallet else {return false}
                return wallet.isHidden
            }
        )
    }
    
    override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
        let view = super.configureHeader(indexPath: indexPath)
        if let view = view as? HiddenWalletsSectionHeaderView {
            view.showHideHiddenWalletsAction = showHideHiddenWalletsAction
            updateHeader(headerView: view)
        }
        return view
    }
    
    override func mapDataToCollectionViewItems() -> [BECollectionViewItem] {
        let viewModel = self.viewModel as? WalletsRepository
        if viewModel?.isHiddenWalletsShown.value == true {
            return super.mapDataToCollectionViewItems()
        } else {
            return []
        }
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        if let headerView = self.headerView() as? HiddenWalletsSectionHeaderView {
            updateHeader(headerView: headerView)
        }
    }
    
    private func updateHeader(headerView: HiddenWalletsSectionHeaderView) {
        let viewModel = self.viewModel as! WalletsRepository
        let shouldUpdateHeight = headerView.setUp(
            isHiddenWalletsShown: viewModel.isHiddenWalletsShown.value,
            hiddenWalletList: viewModel.hiddenWallets()
        )
        
        if shouldUpdateHeight {
            let context = UICollectionViewLayoutInvalidationContext()
            context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: [.init(row: 0, section: 1)])
            collectionView?.relayout(context)
        }
        
//        var shouldRelayout = false
//        if viewModel.hiddenWallets().isEmpty {
//            if headerView.stackView.isDescendant(of: headerView) {
//                shouldRelayout = true
//                headerView.removeStackView()
//            }
//        } else {
//            if !headerView.stackView.isDescendant(of: headerView) {
//                shouldRelayout = true
//                headerView.addStackView()
//            }
//        }
//        if shouldRelayout {
//            collectionView?.relayout()
//        }
    }
}
