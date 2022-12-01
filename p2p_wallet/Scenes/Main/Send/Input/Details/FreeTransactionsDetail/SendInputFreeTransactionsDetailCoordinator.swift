import Combine
import SwiftUI

final class SendInputFreeTransactionsDetailCoordinator: Coordinator<Void> {
    private var transition: PanelTransition?
    private var feeController: UIViewController?

    private let parentController: UIViewController
    private var subject = PassthroughSubject<Void, Never>()

    init(parentController: UIViewController) {
        self.parentController = parentController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SendInputFreeTransactionsDetailView { [weak self] in
            self?.feeController?.dismiss(animated: true)
            self?.subject.send(completion: .finished)
        }

        transition = PanelTransition()
        transition?.containerHeight = 484.adaptiveHeight
        let feeController = UIHostingController(rootView: view)
        feeController.view.layer.cornerRadius = 20
        feeController.transitioningDelegate = transition
        feeController.modalPresentationStyle = .custom

        transition?.dimmClicked
            .sink { [weak self] in
                self?.feeController?.dismiss(animated: true)
                self?.subject.send(completion: .finished)
            }
            .store(in: &subscriptions)
        parentController.present(feeController, animated: true)
        self.feeController = feeController

        return subject.eraseToAnyPublisher()
    }
}
