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
        UIView.spacer
    ])
    
    lazy var backButton = UIImageView(width: 14, height: 24, image: UIImage(systemName: "chevron.left"), tintColor: .h5887ff)
    lazy var titleLabel = UILabel(textSize: 17, weight: .semibold, numberOfLines: 0, textAlignment: .center)
    
    override func commonInit() {
        super.commonInit()
        stackView.spacing = 8
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 18, y: 12))
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
}
