import Combine
import SwiftUI

final class SellSOLInfoCoordinator: Coordinator<Void> {
    private var transition: PanelTransition?
    private var viewController: UIViewController?

    private let parentController: UIViewController
    private var subject = PassthroughSubject<Void, Never>()

    init(parentController: UIViewController) {
        self.parentController = parentController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SellSOLInfoView { [weak self] in
            self?.viewController?.dismiss(animated: true)
            self?.subject.send(completion: .finished)
        }

        transition = PanelTransition()
        transition?.containerHeight = 428.adaptiveHeight
        let viewController = UIHostingController(rootView: view)
        viewController.view.layer.cornerRadius = 20
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom

        transition?.dimmClicked
            .sink { [weak self] in
                self?.viewController?.dismiss(animated: true)
                self?.subject.send(completion: .finished)
            }
            .store(in: &subscriptions)
        parentController.present(viewController, animated: true)
        self.viewController = viewController

        return subject.eraseToAnyPublisher()
    }
}
