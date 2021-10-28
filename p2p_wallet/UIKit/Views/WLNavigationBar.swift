//
//  WLNavigationBar.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation

class WLNavigationBar: BEView {
    lazy var stackView = UIStackView(axis: .horizontal, alignment: .fill, distribution: .equalCentering, arrangedSubviews: [
        leftItems,
        centerItems,
        rightItems
    ])
    
    lazy var leftItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        backButton
    ])
    lazy var centerItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        titleLabel
    ])
    lazy var rightItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        UIView(width: 35, height: 35)
    ])
    
    lazy var backButton = UIImageView(width: 35, height: 35, image: .backSquare)
    lazy var titleLabel: UILabel = {
        let label = UILabel(textSize: 19, weight: .semibold, textAlignment: .center)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    override func commonInit() {
        super.commonInit()
        stackView.spacing = 8
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea(with: .init(all: 20))
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
}
