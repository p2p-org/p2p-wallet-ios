//
//  DashedButton.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

class DashedButton: WLButton {
    lazy var borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.textSecondary.cgColor
        layer.lineDashPattern = [2, 2]
        layer.fillColor = nil
        return layer
    }()

    init(title: String) {
        super.init(frame: .zero)
        configureForAutoLayout()
        autoSetDimension(.height, toSize: 36)

        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        setTitleColor(.textSecondary, for: .normal)
        contentEdgeInsets = UIEdgeInsets(x: 28, y: 0)

        layer.addSublayer(borderLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 18).cgPath
    }
}
