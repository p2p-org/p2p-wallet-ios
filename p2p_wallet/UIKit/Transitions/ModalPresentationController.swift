import UIKit

class ModalPresentationController: UIPresentationController {
    private let tapFadeViewToDismiss: Bool
    
    init(presentedViewController: UIViewController, presenting: UIViewController?, tapFadeViewToDismiss: Bool) {
        self.tapFadeViewToDismiss = tapFadeViewToDismiss
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    lazy var fadeView: UIView = {
        let view = UIView(backgroundColor: .black.withAlphaComponent(0.3))
        view.alpha = 0
        if tapFadeViewToDismiss {
            view.onTap { [unowned self] in
                self.presentedViewController.dismiss(animated: true)
            }
        }
        return view
    }()

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        containerView.insertSubview(fadeView, at: 0)
        fadeView.autoPinEdgesToSuperviewEdges()

        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.fadeView.alpha = 1.0
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            fadeView.alpha = 0.0
            return
        }

        if !coordinator.isInteractive {
            coordinator.animate(alongsideTransition: { _ in
                self.fadeView.alpha = 0.0
            })
        }
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView, let presentedView = presentedView else { return .zero }

        let inset: CGFloat = 0
        let safeAreaFrame = containerView.bounds.inset(by: containerView.safeAreaInsets)

        let targetWidth = safeAreaFrame.width - 2 * inset
        
        var targetHeight: CGFloat = 0
        if let presentedViewController = presentedViewController as? CustomPresentableViewController
        {
            targetHeight = presentedViewController.calculateFittingHeightForPresentedView(targetWidth: targetWidth)
        } else {
            targetHeight = presentedView.fittingHeight(targetWidth: targetWidth)
        }
        
        if targetHeight > safeAreaFrame.size.height {
            var frame = safeAreaFrame
            frame.size.height += containerView.safeAreaInsets.bottom
            return frame
        }

        var frame = safeAreaFrame
        frame.origin.x += inset
        frame.origin.y += frame.size.height - targetHeight
        frame.size.width = targetWidth
        frame.size.height = targetHeight + containerView.safeAreaInsets.bottom

        return frame
    }
}
