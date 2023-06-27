import UIKit

protocol CustomPresentableViewController: UIViewController {
    var transitionManager: UIViewControllerTransitioningDelegate? { get set }
    var dismissalHandlingScrollView: UIScrollView? { get }
    func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat
    func updatePresentationLayout(animated: Bool)
}

extension CustomPresentableViewController {
    var dismissalHandlingScrollView: UIScrollView? { nil }

    func updatePresentationLayout(animated: Bool = false) {
        presentationController?.containerView?.setNeedsLayout()
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0.0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: 0.0,
                options: .allowUserInteraction,
                animations: {
                    self.presentationController?.containerView?.layoutIfNeeded()
                },
                completion: nil
            )
        } else {
            presentationController?.containerView?.layoutIfNeeded()
        }
    }
}
