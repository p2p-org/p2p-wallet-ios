//
//  WCVFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

class WCVFooterView: SectionFooterView {
    lazy var addCoinButton: UIButton = {
        let button = UIButton(height: 36, label: "+ \(L10n.addCoin)", labelFont: .systemFont(ofSize: 12, weight: .semibold), textColor: .secondary, contentInsets: UIEdgeInsets(x: 28, y: 0))
        button.layer.addSublayer(borderLayer)
        return button
    }()
    
    lazy var borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.secondary.cgColor
        layer.lineDashPattern = [2, 2]
        layer.fillColor = nil
        return layer
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = addCoinButton.bounds
        borderLayer.path = UIBezierPath(roundedRect: addCoinButton.bounds, cornerRadius: 18).cgPath
    }
    
    override func commonInit() {
        addSubview(addCoinButton)
        addCoinButton.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
        addCoinButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)
        addCoinButton.autoAlignAxis(toSuperviewAxis: .vertical)
    }
}
