import Combine
import SwiftUI

final class SendInputFreeTransactionsDetailCoordinator: Coordinator<Void> {
    private var transition: PanelTransition?
    private var feeController: UIViewController?

    private let parentController: UIViewController
    private let isFreeTransactionsLimited: Bool
    private var subject = PassthroughSubject<Void, Never>()

    init(parentController: UIViewController, isFreeTransactionsLimited: Bool) {
        self.parentController = parentController
        self.isFreeTransactionsLimited = isFreeTransactionsLimited
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SendInputFreeTransactionsDetailView(
            isFreeTransactionsLimited: isFreeTransactionsLimited
        ) { [weak self] in
            self?.feeController?.dismiss(animated: true)
            self?.subject.send(completion: .finished)
        }

        transition = PanelTransition()
        transition?.containerHeight = 452
        let feeController = UIHostingController(rootView: view, ignoresKeyboard: true)
        feeController.view.layer.cornerRadius = 20
        feeController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
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
