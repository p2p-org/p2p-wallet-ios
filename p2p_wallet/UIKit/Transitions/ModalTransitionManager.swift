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
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source _: UIViewController
    ) -> UIPresentationController? {
        ModalPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            tapFadeViewToDismiss: tapFadeViewToDismiss
        )
    }

    func animationController(
        forPresented _: UIViewController,
        presenting _: UIViewController,
        source _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        ModalTransitionAnimator(presenting: true)
    }

    func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        ModalTransitionAnimator(presenting: false)
    }

    func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning?
    {
        guard let interactionController = interactionController, interactionController.interactionInProgress else {
            return nil
        }
        return interactionController
    }
}
