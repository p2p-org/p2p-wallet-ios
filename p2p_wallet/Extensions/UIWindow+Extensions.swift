import Foundation

extension UIWindow {
    func animate(newRootViewController: UIViewController) {
        rootViewController = newRootViewController
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }
}
