import Foundation
import UIKit

extension UIView {
    func showIndetermineHud() {
        // Hide all previous hud
        hideHud()

        // show new hud
        showLoadingIndicatorView()
    }

    func hideHud() {
        hideLoadingIndicatorView()
    }
}

extension UIView {
    func asImageInBackground() -> UIImage {
        layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
}
