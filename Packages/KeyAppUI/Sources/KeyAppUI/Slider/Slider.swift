import UIKit
import CoreGraphics
import BEPureLayout

public final class Slider: BECompositionView {

    private let count: Int
    private var dots: [CALayer] = []
    private var currentDot: Int = 0

    private var activeColor: UIColor { tintColor }
    private var nonActiveColor: UIColor { tintColor.withAlphaComponent(0.6) }

    public init(count: Int = 4) {
        self.count = count
        super.init()
    }

    // MARK: - Public

    public func nextDot() {
        let prevCurrentDot = currentDot
        currentDot = currentDot == count - 1 ? .zero : currentDot + 1
        animateForward(oldDot: dots[prevCurrentDot], newDot: dots[currentDot])
    }

    public func prevDot() {
        let prevCurrentDot = currentDot
        currentDot = currentDot == .zero ? count - 1 : currentDot - 1
        animateBackward(oldDot: dots[prevCurrentDot], newDot: dots[currentDot])
    }

    // MARK: - Overriden

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard dots.isEmpty else { return }
        drawDots()
    }

    public override func build() -> UIView {
        BEContainer()
        .setup { cont in
            let widthConstant = (Constants.dotSize.width + Constants.space) * CGFloat(count - 1) + Constants.indicatorSize.width
            let height = cont.heightAnchor.constraint(equalToConstant: Constants.dotSize.height)
            height.isActive = true
            let width = cont.widthAnchor.constraint(equalToConstant: widthConstant)
            width.isActive = true
        }
    }

    // MARK: - Private

    private func drawDots() {
        var lastX = CGFloat.zero
        for i in 0...count - 1 {
            var size = Constants.dotSize
            var fillColor = nonActiveColor
            if currentDot == i {
                size = Constants.indicatorSize
                fillColor = activeColor
            }
            drawDot(
                rect: CGRect(
                    origin: CGPoint(x: lastX, y: 0),
                    size: size
                ),
                fillColor: fillColor
            )
            lastX += size.width + Constants.space
        }
    }

    private func drawDot(rect: CGRect, fillColor: UIColor) {
        let layer = CALayer()
        layer.frame = rect
        layer.backgroundColor = fillColor.cgColor
        layer.cornerRadius = Constants.dotSize.width / 2
        self.layer.addSublayer(layer)
        self.dots.append(layer)
    }

    private func animateForward(oldDot: CALayer, newDot: CALayer) {
        let dotSize = Constants.dotSize
        let currentDotSize = Constants.indicatorSize
        var finalFrames: [CALayer: CGRect] = [:]

        let oldRect: CGRect = CGRect(
            origin: CGPoint(x: dots.last == oldDot ? oldDot.frame.maxX : oldDot.frame.minX, y: 0),
            size: dotSize
        )
        finalFrames[oldDot] = oldRect

        let newRect = CGRect(
            origin: dots.first == newDot ? .zero : CGPoint(x: oldRect.maxX + Constants.space, y: 0),
            size: currentDotSize
        )
        finalFrames[newDot] = newRect

        CATransaction.begin()
        oldDot.add(animation(from: oldDot.position, to: oldRect.origin), forKey: Constants.animationKey)
        newDot.add(animation(from: newDot.position, to: newRect.origin), forKey: Constants.animationKey)

        if dots.first == newDot {
            dots.dropFirst().forEach { dotLayer in
                let dotRect = CGRect(
                    origin: CGPoint(x: dotLayer.frame.minX + currentDotSize.width - dotSize.width, y: 0),
                    size: dotSize
                )
                dotLayer.add(animation(from: dotLayer.position, to: dotRect.origin), forKey: Constants.animationKey)
                finalFrames[dotLayer] = dotRect
            }
        }

        CATransaction.setCompletionBlock {
            oldDot.backgroundColor = self.nonActiveColor.cgColor
            newDot.backgroundColor = self.activeColor.cgColor
            finalFrames.forEach { $0.key.frame = $0.value }
        }
        CATransaction.commit()
    }

    private func animateBackward(oldDot: CALayer, newDot: CALayer) {
        let dotSize = Constants.dotSize
        let currentDotSize = Constants.indicatorSize
        var finalFrames: [CALayer: CGRect] = [:]

        let oldRect: CGRect = CGRect(
            origin: dots.first == oldDot ? .zero : CGPoint(x: oldDot.frame.maxX - dotSize.width, y: 0),
            size: dotSize
        )
        finalFrames[oldDot] = oldRect

        let newRect = CGRect(
            origin: CGPoint(x: newDot.frame.maxX - (dots.last == newDot ? currentDotSize.width : Constants.space), y: 0),
            size: currentDotSize
        )
        finalFrames[newDot] = newRect

        CATransaction.begin()
        oldDot.add(animation(from: oldDot.position, to: oldRect.origin), forKey: Constants.animationKey)
        newDot.add(animation(from: newDot.position, to: newRect.origin), forKey: Constants.animationKey)

        if dots.last == newDot {
            dots.dropLast().dropFirst().forEach { dotLayer in
                let dotRect = CGRect(
                    origin: CGPoint(x: dotLayer.frame.minX - currentDotSize.width + Constants.space, y: 0),
                    size: dotSize
                )
                dotLayer.add(animation(from: dotLayer.position, to: dotRect.origin), forKey: Constants.animationKey)
                finalFrames[dotLayer] = dotRect
            }
        }

        CATransaction.setCompletionBlock {
            oldDot.backgroundColor = self.nonActiveColor.cgColor
            newDot.backgroundColor = self.activeColor.cgColor
            finalFrames.forEach { $0.key.frame = $0.value }
        }
        CATransaction.commit()
    }

    private func animation(from oldPosition: CGPoint?, to newPosition: CGPoint?) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: Constants.animationKey)
        animation.fromValue = oldPosition
        animation.toValue = newPosition
        animation.duration = Constants.animationDuration
        return animation
    }
}

private extension Slider {
    enum Constants {
        static let dotSize = CGSize(width: 8, height: 8)
        static let indicatorSize = CGSize(width: 32, height: 8)
        static let space: CGFloat = 8
        static let animationDuration = 0.3
        static let animationKey = "position"
    }
}
