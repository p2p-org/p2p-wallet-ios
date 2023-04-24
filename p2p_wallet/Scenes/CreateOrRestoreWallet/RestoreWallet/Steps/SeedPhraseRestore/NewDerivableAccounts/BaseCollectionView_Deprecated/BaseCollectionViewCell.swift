//
//  BaseCollectionViewCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
//import ListPlaceholder

class BaseCollectionViewCell: UICollectionViewCell {
    var padding: UIEdgeInsets { .init(all: 20) }

    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    @available(*, unavailable,
               message: "Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: padding)
    }

    func showLoading() {
        // ListPlaceholder is removed, as ChoosePhoneCode and NewDerivableAccounts (last BECollectionView_Combine(s)) do not require loading
//        stackView.hideLoader()
//        stackView.showLoader(customGradientColor: .defaultLoaderGradientColors)
    }

    func hideLoading() {
//        stackView.hideLoader()
    }
}
