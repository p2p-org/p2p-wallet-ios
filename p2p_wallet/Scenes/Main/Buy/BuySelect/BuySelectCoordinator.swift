import Combine
import Foundation
import Resolver
import SolanaSwift
import SwiftUI

enum BuySelectCoordinatorResult<Model: Hashable> {
    case result(model: Model)
    case cancel
}

final class BuySelectCoordinator<Model, Cell: BuySelectViewModelCell>:
Coordinator<BuySelectCoordinatorResult<Model>>where Model == Cell.Model {
    private let navigationController: UINavigationController
    private let items: [Model]
    private let transition = PanelTransition()
    private let contentHeight: CGFloat
    private var viewModel: BuySelectViewModel<Model>
    private var selectedModel: Model?
    private var title: String

    init(
        title: String,
        navigationController: UINavigationController,
        items: [Model],
        contentHeight: CGFloat = 0,
        selectedModel: Model? = nil
    ) {
        self.title = title
        self.navigationController = navigationController
        self.items = items
        self.contentHeight = contentHeight
        self.selectedModel = selectedModel

        viewModel = BuySelectViewModel<Model>(
            items: items,
            selectedModel: selectedModel
        )
    }

    private let viewControllerDismissed = PassthroughSubject<Void, Never>()

    override func start() -> AnyPublisher<BuySelectCoordinatorResult<Model>, Never> {
        let view = BuySelectView<Model, Cell>(viewModel: viewModel, title: title)
        let viewController = UIHostingController(rootView: view)

        transition.containerHeight = contentHeight
        viewController.view.layer.cornerRadius = 16
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom
        navigationController.present(viewController, animated: true)

        viewController.onClose = { [weak self] in
            self?.viewControllerDismissed.send()
        }

        return Publishers.Merge(
            // Dismiss events
            Publishers.MergeMany(
                viewModel.coordinatorIO.didDissmiss.eraseToAnyPublisher(),
                viewControllerDismissed.eraseToAnyPublisher(),
                transition.dimmClicked.eraseToAnyPublisher()
            )
                .map { BuySelectCoordinatorResult.cancel },
            viewModel.coordinatorIO.didSelectModel.map { BuySelectCoordinatorResult.result(model: $0) }
        ).handleEvents(receiveOutput: { _ in
            viewController.dismiss(animated: true)
        }).prefix(1).eraseToAnyPublisher()
    }
}
