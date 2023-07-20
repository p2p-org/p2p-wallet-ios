// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import UIKit

public class CircularProgressIndicator: UIView {
    var backgroundLayer: CALayer? {
        willSet {
            backgroundLayer?.removeFromSuperlayer()
        }
        didSet {
            guard let backgroundLayer = backgroundLayer else { return }
            layer.addSublayer(backgroundLayer)
        }
    }

    var foregroundLayer: CALayer? {
        willSet {
            foregroundLayer?.removeFromSuperlayer()
        }
        didSet {
            guard let foregroundLayer = foregroundLayer else { return }
            layer.addSublayer(foregroundLayer)
        }
    }

    private var foregroundAnimation: CABasicAnimation? {
        didSet {
            foregroundLayer?.removeAllAnimations()
            guard let foregroundAnimation = foregroundAnimation else { return }
            foregroundLayer?.add(foregroundAnimation, forKey: "rotationAnimation")
        }
    }

    var lineWidth: CGFloat = 2 {
        didSet { drawAllLayers() }
    }

    var backgroundCircularColor: UIColor {
        didSet {
            guard let backgroundLayer = backgroundLayer as? CAShapeLayer else { return }
            backgroundLayer.strokeColor = backgroundCircularColor.cgColor
        }
    }

    var foregroundCircularColor: UIColor {
        didSet {
            guard let foregroundLayer = foregroundLayer as? CAShapeLayer else { return }
            foregroundLayer.strokeColor = foregroundCircularColor.cgColor
        }
    }

    let progressLineLength: CGFloat = 0.25

    public convenience init() {
        self.init(
            backgroundCircularColor: Asset.Colors.night.color,
            foregroundCircularColor: Asset.Colors.lime.color
        )
    }

    public init(
        backgroundCircularColor: UIColor = Asset.Colors.night.color,
        foregroundCircularColor: UIColor = Asset.Colors.lime.color
    ) {
        self.backgroundCircularColor = backgroundCircularColor
        self.foregroundCircularColor = foregroundCircularColor

        super.init(frame: .zero)

        drawAllLayers()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override public func layoutSubviews() {
        drawAllLayers()
        super.layoutSubviews()
    }

    func drawAllLayers() {
        drawBackgroundLayer()
        drawForegroundLayer()
        startAnimation()
    }

    func drawBackgroundLayer() {
        let segmentPath = createSegment(startAngle: 0, endAngle: 360)
        let segmentLayer = CAShapeLayer()
        segmentLayer.path = segmentPath.cgPath
        segmentLayer.lineWidth = lineWidth
        segmentLayer.strokeColor = backgroundCircularColor.cgColor
        segmentLayer.fillColor = UIColor.clear.cgColor

        backgroundLayer = segmentLayer
    }

    func drawForegroundLayer() {
        let segmentPath = createSegment(startAngle: 0, endAngle: 360)
        let segmentLayer = CAShapeLayer()
        segmentLayer.frame = .init(x: 0, y: 0, width: frame.width, height: frame.height)
        segmentLayer.path = segmentPath.cgPath
        segmentLayer.lineWidth = lineWidth + 0.2
        segmentLayer.strokeStart = 0
        segmentLayer.strokeEnd = progressLineLength
        segmentLayer.strokeColor = foregroundCircularColor.cgColor
        segmentLayer.fillColor = UIColor.clear.cgColor

        foregroundLayer = segmentLayer
    }

    func startAnimation() {
        if isHidden {
            stopAnimation()
            return
        }

        if let foregroundAnimation = foregroundAnimation {
            foregroundLayer?.add(foregroundAnimation, forKey: "rotationAnimation")
        } else {
            let foregroundAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            foregroundAnimation.fromValue = 0
            foregroundAnimation.toValue = 2 * Double.pi
            foregroundAnimation.duration = 1
            foregroundAnimation.repeatCount = .infinity
            foregroundAnimation.isRemovedOnCompletion = false

            self.foregroundAnimation = foregroundAnimation
        }
    }

    func stopAnimation() {
        foregroundLayer?.removeAllAnimations()
    }

    private func createSegment(startAngle: CGFloat, endAngle: CGFloat) -> UIBezierPath {
        UIBezierPath(
            arcCenter: CGPoint(x: frame.width / 2, y: frame.height / 2),
            radius: min(frame.width / 2, frame.width / 2),
            startAngle: startAngle.toRadians(),
            endAngle: endAngle.toRadians(),
            clockwise: true
        )
    }

    override public var isHidden: Bool {
        didSet {
            if isHidden { stopAnimation() } else { startAnimation() }
        }
    }
}

extension CGFloat {
    func toRadians() -> CGFloat { self * CGFloat(Double.pi) / 180.0 }
}
