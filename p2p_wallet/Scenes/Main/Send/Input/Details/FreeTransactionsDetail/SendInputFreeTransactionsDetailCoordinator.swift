import Combine
import SwiftUI

final class SendInputFreeTransactionsDetailCoordinator: Coordinator<Void> {
    private let parentController: UIViewController
    private var feeController: UIViewController?

    init(parentController: UIViewController) {
        self.parentController = parentController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SendInputFreeTransactionsDetailView { [weak self] in
            self?.feeController?.dismiss(animated: true)
        }

        let feeController = BottomSheetController(rootView: view)
        parentController.present(feeController, animated: true)
        self.feeController = feeController
        return feeController.deallocatedPublisher().prefix(1).eraseToAnyPublisher()
    }
}
