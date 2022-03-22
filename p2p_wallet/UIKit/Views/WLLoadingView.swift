//
//  WLLoadingView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/12/2020.
//

import Foundation

open class WLLoadingView: BEView {
    var isLoading = false

    lazy var fillLayer = CALayer()

    override open func commonInit() {
        super.commonInit()
        fillLayer.backgroundColor = UIColor.textWhite.withAlphaComponent(0.5).cgColor
    }

    func setUp(loading: Bool) {
        isLoading = loading

        if loading {
            fillLayer.removeFromSuperlayer()
            layer.insertSublayer(fillLayer, at: 1)
            layer.position = .zero
            fillLayer.frame.size = bounds.size
            let anim = CABasicAnimation(keyPath: "position.x")
            anim.fromValue = 0
            anim.toValue = bounds.size.width
            anim.repeatCount = .infinity
            anim.duration = 5
            fillLayer.add(anim, forKey: "positionX")
        } else {
            fillLayer.removeFromSuperlayer()
        }
    }
}
