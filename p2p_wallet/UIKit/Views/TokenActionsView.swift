//
//  ColorfulHorizontalView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 19.01.2022.
//

import BEPureLayout
import UIKit

final class TokenActionsView: BEView {
    private let contentView = UIStackView(axis: .horizontal, alignment: .fill, distribution: .equalSpacing)

    init() {
        super.init(frame: .zero)

        addSubview(contentView)
        contentView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        contentView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        contentView.spacing = 32
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
