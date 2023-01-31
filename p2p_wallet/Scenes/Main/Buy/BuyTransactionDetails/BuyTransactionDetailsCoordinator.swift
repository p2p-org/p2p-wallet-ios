import AnalyticsManager
import Combine
import Resolver
import UIKit

final class BuyTransactionDetailsCoordinator: Coordinator<Void> {
    @Injected private var analyticsManager: AnalyticsManager
    private let controller: UIViewController
    private let model: BuyTransactionDetailsView.Model

    init(
        controller: UIViewController,
        model: BuyTransactionDetailsView.Model
    ) {
        self.controller = controller
        self.model = model
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = BuyTransactionDetailsView(model: model)
        let viewController = BottomSheetController(title: L10n.transactionDetails, rootView: view)
        viewController.modalPresentationStyle = .custom
        controller.present(viewController, animated: true)
        analyticsManager.log(event: AmplitudeEvent.buyTotalShowed)

        return Publishers.Merge(
            view.dismiss.handleEvents(receiveOutput: { _ in
                viewController.dismiss(animated: true)
            }),
            controller.deallocatedPublisher()
        ).prefix(1).eraseToAnyPublisher()
    }
}
