//
//  TabBar.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

class TabBar: BERoundedCornerShadowView {
    override func commonInit() {
        super.commonInit()
        stackView.spacing = 0
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
    }

    override func layoutStackView() {
        stackView.autoPinEdgesToSuperviewSafeArea(with: contentInset)
    }

    override func roundCorners() {
        mainView.roundCorners([.topLeft, .topRight], radius: mainViewCornerRadius)
    }
}

extension TabBarVC {
    final class TabBarItemView: BEView {
        lazy var imageView = UIImageView(width: 24, height: 24)
        lazy var titleLabel = UILabel(textSize: 10, weight: .medium, textAlignment: .center)

        override var tintColor: UIColor! {
            didSet {
                imageView.tintColor = tintColor
                titleLabel.textColor = tintColor
            }
        }

        override func commonInit() {
            super.commonInit()
            let stackView = UIStackView(
                axis: .vertical,
                spacing: 3,
                alignment: .center,
                distribution: .fill,
                arrangedSubviews: [
                    imageView, titleLabel,
                ]
            )

            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
    }
}
