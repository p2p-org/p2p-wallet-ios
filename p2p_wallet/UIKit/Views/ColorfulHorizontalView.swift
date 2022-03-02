//
//  ColorfulHorizontalView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 19.01.2022.
//

import UIKit
import BEPureLayout

final class ColorfulHorizontalView: BEView {
    private let colorfulImageView = ColorfulRadialGradientView()
    private let contentView = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually)

    init() {
        super.init(frame: .zero)

        addSubview(colorfulImageView)
        colorfulImageView.autoPinEdgesToSuperviewEdges()

        addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges(with: .init(all: 4, excludingEdge: nil))
        contentView.backgroundColor = .white.withAlphaComponent(0.1)
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        layer.cornerRadius = 16
        layer.masksToBounds = true
    }
    
    convenience init(@BEViewBuilder builder: Builder) {
        self.init()
        setArrangedSubviews(builder())
    }

    func setArrangedSubviews(_ arrangesSubviews: [UIView]) {
        contentView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contentView.addArrangedSubviews(arrangesSubviews)
    }
}
