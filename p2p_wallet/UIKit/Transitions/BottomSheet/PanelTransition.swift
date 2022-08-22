//
//  PanelTransition.swift
//  p2p_wallet
//
//  Created by Ivan on 19.08.2022.
//

import Combine
import UIKit

class PanelTransition: NSObject, UIViewControllerTransitioningDelegate {
    private var cancellables = Set<AnyCancellable>()
    private let subject = PassthroughSubject<Void, Never>()
    var dimmClicked: AnyPublisher<Void, Never> { subject.eraseToAnyPublisher() }

    private let driver = TransitionDriver()

    var containerHeight: CGFloat = 0

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        driver.link(to: presented)
        let presentationController = DimmPresentationController(
            presentedViewController: presented,
            presenting: presenting ?? source
        )
        presentationController.containerHeight = containerHeight
        presentationController.driver = driver
        presentationController.dimmClicked
            .sink(receiveValue: { [weak self] in
                self?.subject.send()
            })
            .store(in: &cancellables)

        return presentationController
    }

    // MARK: - Animation

    func animationController(
        forPresented _: UIViewController,
        presenting _: UIViewController,
        source _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        PresentAnimation()
    }

    func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DismissAnimation()
    }

    // MARK: - Interaction

    func interactionControllerForPresentation(using _: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning? {
        driver
    }

    func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning? {
        driver
    }
}
