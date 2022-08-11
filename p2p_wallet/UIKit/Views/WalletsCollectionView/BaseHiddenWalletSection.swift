//
//  BaseHiddenWalletSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/03/2021.
//

import BECollectionView_Combine
import Foundation
import SolanaSwift

class HiddenWalletsSectionHeaderView: BECollectionCell {
    var showHideHiddenWalletsAction: (() -> Void)?

    private let imageRef = BERef<UIImageView>()

    override func build() -> UIView {
        BEHStack {
            UILabel(text: L10n.hiddenTokens, textSize: 13, weight: .medium, textColor: .secondaryLabel)
            UIImageView(image: .chevronDown, tintColor: .secondaryLabel)
                .bind(imageRef)
            UIView.spacer
        }
        .frame(height: 18)
        .padding(.init(top: 18, left: 18, bottom: 18, right: 0))
        .onTap { [unowned self] in showHideHiddenWalletsAction?() }
    }

    @discardableResult
    func setUp(isHiddenWalletsShown: Bool, hiddenWalletList: [Wallet]) -> Bool {
        guard let imageView = imageRef.view else { return false }

        contentView.isHidden = hiddenWalletList.isEmpty
        let image = isHiddenWalletsShown ? UIImage.chevronUp : UIImage.chevronDown
        UIView.transition(with: imageView,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { self.imageRef.view?.image = image },
                          completion: nil)

        return false
    }

    @objc func stackViewDidTouch() {
        showHideHiddenWalletsAction?()
    }
}

class HiddenWalletsSection: WalletsSection {
    var showHideHiddenWalletsAction: (() -> Void)?

    init(
        index: Int,
        viewModel: WalletsRepository,
        header: BECollectionViewSectionHeaderLayout = .init(
            viewClass: HiddenWalletsSectionHeaderView.self
        ),
        footer: BECollectionViewSectionFooterLayout? = nil,
        background: UICollectionReusableView.Type? = nil,
        onSend: BECallback<Wallet>? = nil,
        showHideHiddenWalletsAction: (() -> Void)?
    ) {
        self.showHideHiddenWalletsAction = showHideHiddenWalletsAction
        super.init(
            index: index,
            viewModel: viewModel,
            header: header,
            footer: footer,
            background: background,
            cellType: HidedWalletCell.self,
            numberOfLoadingCells: 0,
            customFilter: { item in
                guard let wallet = item as? Wallet else { return false }
                return wallet.isHidden
            },
            onSend: onSend
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
        if viewModel?.isHiddenWalletsShown == true {
            return super.mapDataToCollectionViewItems()
        } else {
            return []
        }
    }

    override func dataDidLoad() {
        super.dataDidLoad()
        if let headerView = headerView() as? HiddenWalletsSectionHeaderView {
            updateHeader(headerView: headerView)
        }
    }

    private func updateHeader(headerView: HiddenWalletsSectionHeaderView) {
        let viewModel = self.viewModel as! WalletsRepository
        let shouldUpdateHeight = headerView.setUp(
            isHiddenWalletsShown: viewModel.isHiddenWalletsShown,
            hiddenWalletList: viewModel.hiddenWallets()
        )

        if shouldUpdateHeight {
            let context = UICollectionViewLayoutInvalidationContext()
            context.invalidateSupplementaryElements(
                ofKind: UICollectionView.elementKindSectionHeader,
                at: [.init(row: 0, section: 1)]
            )
            collectionView?.relayout(context)
        }
    }
}
