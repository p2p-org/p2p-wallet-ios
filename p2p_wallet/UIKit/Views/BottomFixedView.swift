//
//  BottomFixedView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.12.2021.
//

import UIKit
import BEPureLayout

final class BottomFixedView: BEView {
    init(content: UIView) {
        super.init(frame: .zero)

        layout(content: content)
        addShadow()
    }

    func setConstraints() {
        autoPinEdge(toSuperviewEdge: .leading)
        autoPinEdge(toSuperviewEdge: .trailing)

        autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
    }

    private func addShadow() {
        backgroundColor = .white
        layer.shadowColor = UIColor(red: 0.221, green: 0.234, blue: 0.279, alpha: 0.05).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }

    private func layout(content: UIView) {
        addSubview(content)

        content.autoPinEdgesToSuperviewSafeArea(with: .init(all: 18))
    }
}
