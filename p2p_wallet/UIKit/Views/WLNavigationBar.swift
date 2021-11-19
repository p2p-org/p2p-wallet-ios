//
//  WLNavigationBar.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2021.
//

import Foundation

class WLNavigationBar: BEView {
    lazy var leftItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill, arrangedSubviews: [
        backButton
    ])
    lazy var centerItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        titleLabel
    ])
    lazy var rightItems = UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        UIView.spacer
    ])
    
    lazy var backButton = UIImageView(width: 14, height: 24, image: UIImage(systemName: "chevron.left"), tintColor: .h5887ff)
        .padding(.init(x: 6, y: 4))
    lazy var titleLabel = UILabel(textSize: 17, weight: .semibold, numberOfLines: 0, textAlignment: .center)

    override func commonInit() {
        super.commonInit()

        addSubview(leftItems)
        addSubview(centerItems)
        addSubview(rightItems)

        self.autoSetDimension(.height, toSize: 48)
        leftItems.autoPinEdgesToSuperviewEdges(with: .init(top: 0, left: 12, bottom: 0, right: 0), excludingEdge: .right)

        centerItems.autoAlignAxis(toSuperviewAxis: .vertical)
        centerItems.autoPinEdge(.left, to: .right, of: leftItems, withOffset: 8, relation: .greaterThanOrEqual)
        centerItems.autoPinEdge(.right, to: .left, of: rightItems, withOffset: 8, relation: .greaterThanOrEqual)
        centerItems.autoPinEdge(toSuperviewEdge: .top)
        centerItems.autoPinEdge(toSuperviewEdge: .bottom)

        rightItems.autoPinEdgesToSuperviewEdges(with: .init(top: 0, left: 0, bottom: 0, right: 18), excludingEdge: .left)

        backgroundColor = .background
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
}
