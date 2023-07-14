import UIKit

class CircularProgressIndicator: UIView {
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

    convenience init() {
        self.init()
    }

    init(
        backgroundCircularColor: UIColor = .init(resource: .night),
        foregroundCircularColor: UIColor = .init(resource: .lime)
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

    override func layoutSubviews() {
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

    override var isHidden: Bool {
        didSet {
            if isHidden { stopAnimation() } else { startAnimation() }
        }
    }
}

extension CGFloat {
    func toRadians() -> CGFloat { self * CGFloat(Double.pi) / 180.0 }
}
