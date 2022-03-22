//
//  BaseCollectionViewCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation

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
        stackView.hideLoader()
        stackView.showLoader(customGradientColor: .defaultLoaderGradientColors)
    }

    func hideLoading() {
        stackView.hideLoader()
    }
}
