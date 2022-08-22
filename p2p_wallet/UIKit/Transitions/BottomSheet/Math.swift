//
//  Math.swift
//  p2p_wallet
//
//  Created by Ivan on 19.08.2022.
//

import UIKit

extension CGFloat {
    func projectedOffset(decelerationRate: UIScrollView.DecelerationRate) -> CGFloat {
        let multiplier = 1 / (1 - decelerationRate.rawValue) / 1000
        return self * multiplier
    }
}

extension CGPoint {
    func projectedOffset(decelerationRate: UIScrollView.DecelerationRate) -> CGPoint {
        CGPoint(
            x: x.projectedOffset(decelerationRate: decelerationRate),
            y: y.projectedOffset(decelerationRate: decelerationRate)
        )
    }
}

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        CGPoint(
            x: left.x + right.x,
            y: left.y + right.y
        )
    }
}

extension UIPanGestureRecognizer {
    func projectedLocation(decelerationRate _: UIScrollView.DecelerationRate) -> CGPoint {
        let velocityOffset = velocity(in: view).projectedOffset(decelerationRate: .normal)
        let projectedLocation = location(in: view!) + velocityOffset
        return projectedLocation
    }
}
