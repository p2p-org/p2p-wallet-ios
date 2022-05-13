//
//  AnimatedCircleCompletionView.swift
//  p2p_wallet
//
//  Created by Ivan on 13.05.2022.
//

import UIKit

final class AnimatedCircleCompletionView: AnimatedProgressView {
    @objc dynamic var strokeWidth: CGFloat {
        get { (layer as! AnimatedCircleCompletionLayer).strokeWidth }
        set { (layer as! AnimatedCircleCompletionLayer).strokeWidth = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        strokeWidth = 1.0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public class var layerClass: AnyClass {
        AnimatedCircleCompletionLayer.self
    }
}
