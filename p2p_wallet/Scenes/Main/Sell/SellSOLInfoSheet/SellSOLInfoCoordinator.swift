import Combine
import SwiftUI

final class SellSOLInfoCoordinator: Coordinator<Void> {
    private var viewController: UIViewController?

    private let parentController: UIViewController
    private var subject = PassthroughSubject<Void, Never>()

    init(parentController: UIViewController) {
        self.parentController = parentController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SellSOLInfoView { [weak self] in self?.finish() }
        let viewController = BottomSheetController(rootView: view)

        viewController.deallocatedPublisher()
            .sink { [weak self] in self?.subject.send() }
            .store(in: &subscriptions)
        parentController.present(viewController, animated: true)
        self.viewController = viewController

        return subject.prefix(1).eraseToAnyPublisher()
    }

    private func finish() {
        self.viewController?.dismiss(animated: true)
        self.subject.send(())
    }
}
