import Foundation
import SwiftUI

extension UIWindow {
    func animate(newRootViewController: UIViewController) {
        rootViewController = newRootViewController
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }
}

extension UIWindow {
    #if !RELEASE
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?) {
        if motion == .motionShake {
            let vc = UIHostingController(rootView: DebugMenuView(viewModel: .init()))
            UIApplication.shared.windows.first?.rootViewController?.present(vc, animated: true)
        }
    }
    #endif
}
