//
//  AnimatedCircleCompletionLayer.swift
//  p2p_wallet
//
//  Created by Ivan on 13.05.2022.
//

import UIKit

class AnimatedCircleCompletionLayer: AnimatedProgressLayer {
    // NSManaged informs the compiler these values will be set
    // at runtime, and removes the "no initializers" compiler error
    @NSManaged var strokeWidth: CGFloat

    override init(layer: Any) {
        super.init(layer: layer)

        if let layer = layer as? AnimatedCircleCompletionLayer {
            strokeWidth = layer.strokeWidth
        }
    }

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)

        // Make ctx the current context
        UIGraphicsPushContext(ctx)

        // The path describes the loading indicator shape
        // at a specific progress value
        var path: UIBezierPath

        // Computes radius, the distance from the center of
        // the bounds to the closest side minus strokeWidth
        let minSideLength = min(
            bounds.size.width,
            bounds.size.height
        )

        let radius = (minSideLength / 2.0) - strokeWidth

        // From start (progress 0) to full circle (progress 0.5)
        if progress < 0.5 {
            let sectionProgress = progress * 2

            path = UIBezierPath(
                arcCenter: bounds.center,
                radius: radius,
                startAngle: 1.5 * .pi,
                endAngle: (2 * .pi * sectionProgress) - (0.5 * .pi),
                clockwise: true
            )
        } else if progress == 0.5 {
            let halfSideLength = (minSideLength / 2.0)
            let rect = CGRect(
                x: bounds.center.x - halfSideLength + strokeWidth,
                y: bounds.center.y - halfSideLength + strokeWidth,
                width: minSideLength - 2 * strokeWidth,
                height: minSideLength - 2 * strokeWidth
            )

            path = UIBezierPath(ovalIn: rect)
        }

        // From full circle (progress 0.5) to start (progress 1.0)
        else {
            let sectionProgress = (0.5 - progress) * 2
            path = UIBezierPath(
                arcCenter: bounds.center,
                radius: radius,
                startAngle: (1.5 * .pi) - (2 * .pi * sectionProgress),
                endAngle: 1.5 * .pi,
                clockwise: true
            )
        }

        // Draw the computed path
        draw(path: path, ctx: ctx)

        // Remove ctx as the current context
        UIGraphicsPopContext()
    }

    internal func draw(path: UIBezierPath, ctx: CGContext) {
        // Set color as the color of the stroke
        ctx.setStrokeColor(color)

        // Configures the line to be drawn at path
        path.lineWidth = strokeWidth
        path.lineCapStyle = .round

        // Outlines the path using the color set
        path.stroke()
    }

    override class func customAnimatable(key: String) -> Bool {
        if key == #keyPath(strokeWidth) { return true }
        return super.customAnimatable(key: key)
    }
}
