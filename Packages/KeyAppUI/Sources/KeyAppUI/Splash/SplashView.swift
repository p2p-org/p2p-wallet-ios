import BEPureLayout
import UIKit

enum SplashConstants {
    static let overlayOffset: CGFloat = 2
    static let underlineHeight: CGFloat = 3
    static let textOffset: CGFloat = 55
    static let centerOffset: CGFloat = 22

    static let keyframes = [0, 0.2, 0.4, 0.6, 0.8, 1]

    static let assets: [(UIImage, UIEdgeInsets)] = [
        (Asset.MaterialIcon.k.image, UIEdgeInsets(top: .zero, left: .zero, bottom: 7, right: .zero)),
        (Asset.MaterialIcon.e.image, UIEdgeInsets(top: 7, left: .zero, bottom: 7, right: 0.6)),
        (Asset.MaterialIcon.y.image, UIEdgeInsets(top: 7, left: .zero, bottom: .zero, right: 5.7)),
        (Asset.MaterialIcon.a.image, UIEdgeInsets(top: 7, left: .zero, bottom: 7, right: 3.7)),
        (Asset.MaterialIcon.p1.image, UIEdgeInsets(top: 7, left: .zero, bottom: .zero, right: 2)),
        (Asset.MaterialIcon.p2.image, .init(only: .top, inset: 7)),
    ]

    static var size: CGSize {
        .init(width: assets.reduce(0) { $0 + $1.0.size.width + $1.1.right }, height: 37)
    }
}

public class SplashView: UIView, CAAnimationDelegate {
    var completionHandler: (() -> Void)?

    override public var intrinsicContentSize: CGSize {
        SplashConstants.size
    }

    public dynamic var progress: CGFloat = 0 {
        didSet {
            progressLayer.progress = progress
        }
    }

    fileprivate var progressLayer: SplashLayer {
        layer as! SplashLayer
    }

    override public class var layerClass: AnyClass {
        SplashLayer.self
    }

    private(set) var isStopped: Bool = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.contentsScale = UIScreen.main.scale
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        layer.contentsScale = UIScreen.main.scale
    }

    public func animate() {
        let animation = CABasicAnimation(keyPath: "progress")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 2
        animation.delegate = self
        layer.add(animation, forKey: "progress")
    }

    public func stopAnimation() {
        layer.removeAnimation(forKey: "progress")
        progress = 0.5
        isStopped = true
    }

    public func animationDidStop(_: CAAnimation, finished _: Bool) {
        if let completionHandler = completionHandler {
            completionHandler()
        } else if !isStopped {
            animate()
        }
    }
}

/*
 * Concepts taken from:
 * https://stackoverflow.com/a/37470079
 */

private class SplashLayer: CALayer {
    @NSManaged var progress: CGFloat

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(progress) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)

        UIGraphicsPushContext(ctx)

        drawLetters()
        drawLine()

        UIGraphicsPopContext()
    }

    private func drawLine() {
        let x: CGFloat
        let width: CGFloat

        if progress <= SplashConstants.keyframes[1] {
            x = 0
            width = 0
        } else if progress <= SplashConstants.keyframes[2] {
            x = 0
            width = (progress - SplashConstants.keyframes[1]) * bounds.width / (SplashConstants.keyframes[2] - SplashConstants.keyframes[1])
        } else if progress <= SplashConstants.keyframes[3] {
            x = 0
            width = bounds.width
        } else if progress <= SplashConstants.keyframes[4] {
            x = 0
            width = bounds.width
        } else {
            x = (progress - SplashConstants.keyframes[4]) * bounds.width / (SplashConstants.keyframes[5] - SplashConstants.keyframes[4])
            width = bounds.width - x
        }

        Asset.Colors.night.color.set()
        let rect = CGRect(x: x, y: bounds.height - SplashConstants.underlineHeight, width: width, height: SplashConstants.underlineHeight)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: SplashConstants.underlineHeight / 2)
        path.fill()
    }

    private func drawLetters() {
        var x: CGFloat = 0
        for (index, asset) in SplashConstants.assets.enumerated() {
            let y: CGFloat

            if progress <= SplashConstants.keyframes[1] {
                y = ((SplashConstants.keyframes[1] - progress) / SplashConstants.keyframes[1]) * (bounds.maxY + CGFloat(10 * index))
            } else if progress <= SplashConstants.keyframes[2] {
                y = 0
            } else if progress <= SplashConstants.keyframes[3] {
                y = 0
            } else if progress <= SplashConstants.keyframes[4] {
                y = ((progress - SplashConstants.keyframes[3]) / (SplashConstants.keyframes[4] - SplashConstants.keyframes[3])) * (bounds.maxY + CGFloat(10 * (SplashConstants.keyframes.count - index)))
            } else {
                y = bounds.maxY
            }
            
            let rect = CGRect(x: x, y: y + asset.1.top, width: asset.0.size.width, height: asset.0.size.height)
            x += asset.0.size.width + asset.1.right
            asset.0.draw(in: rect)
        }
    }
}
