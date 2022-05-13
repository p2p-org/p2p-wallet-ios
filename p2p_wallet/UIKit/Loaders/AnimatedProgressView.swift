//
//  AnimatedProgressView.swift
//  p2p_wallet
//
//  Created by Ivan on 13.05.2022.
//

import UIKit

class AnimatedProgressView: UIView {
    @objc dynamic var progress: CGFloat {
        get { progressLayer.progress }
        set { progressLayer.progress = newValue }
    }

    /// Display color of the progress bar. Animatable.
    @objc dynamic var color: UIColor {
        get { UIColor(cgColor: progressLayer.color) }
        set { progressLayer.color = newValue.cgColor }
    }

    // Convenience variable
    internal var progressLayer: AnimatedProgressLayer {
        layer as! AnimatedProgressLayer
    }

    // Overriding the layer class means AnimatedProgressLayer
    // will be instantiated as the layer property for this view
    override public class var layerClass: AnyClass {
        AnimatedProgressLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        progress = 0
        color = .blue

        // Default the background color to clear
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func progressForever(interval: CFTimeInterval = 4.0, curve: CAMediaTimingFunctionName = .easeOut) {
        let progressAnimationKey = "progress-loop"

        // Only one progress forever animation can be active at a time
        guard layer.animation(forKey: progressAnimationKey) == nil else { return }

        let progressAnimation = CABasicAnimation(keyPath: "progress")

        // Animate from 0 (start) to 1 (end)
        progressAnimation.fromValue = 0.0
        progressAnimation.toValue = 1.0

        // The duration is the length of cycle where
        // progress goes from 0 to 1
        progressAnimation.duration = interval

        // Set repeat to Float.infinity to repeat "forever"
        progressAnimation.repeatCount = Float.infinity

        // The timingFunction, ie curve, changes how long it takes
        // to complete for each step of the animation.
        progressAnimation.timingFunction = CAMediaTimingFunction(name: curve)

        layer.add(progressAnimation, forKey: progressAnimationKey)
    }

    func rotateForever(interval: CFTimeInterval = 4.0, curve _: CAMediaTimingFunctionName = .linear) {
        let rotateAnimationKey = "rotate-loop"

        // Only one rotate forever animation can be active at a time
        guard layer.animation(forKey: rotateAnimationKey) == nil else { return }

        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")

        // Animate from 0 (start) to 2 * pi (end)
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)

        // The duration is the length of cycle where
        // progress goes from 0 to 1
        rotateAnimation.duration = interval

        // Set repeat to Float.infinity to repeat "forever"
        rotateAnimation.repeatCount = Float.infinity

        layer.add(rotateAnimation, forKey: nil)
    }
}
