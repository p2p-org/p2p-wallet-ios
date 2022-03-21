import UIKit

class ModalTransitionManager: NSObject {

    fileprivate let tapFadeViewToDismiss: Bool
    private var interactionController: InteractionControlling?

    init(interactionController: InteractionControlling?, tapFadeViewToDismiss: Bool) {
        self.interactionController = interactionController
        self.tapFadeViewToDismiss = tapFadeViewToDismiss
    }
}

extension ModalTransitionManager: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ModalPresentationController(presentedViewController: presented, presenting: presenting, tapFadeViewToDismiss: tapFadeViewToDismiss)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalTransitionAnimator(presenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalTransitionAnimator(presenting: false)
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionController = interactionController, interactionController.interactionInProgress else {
            return nil
        }
        return interactionController
    }
}
