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
    private let controller: UIViewController
    private let items: [Model]
    private var viewModel: BuySelectViewModel<Model>
    private var selectedModel: Model?
    private var title: String

    init(
        title: String,
        controller: UIViewController,
        items: [Model],
        selectedModel: Model? = nil
    ) {
        self.title = title
        self.controller = controller
        self.items = items
        self.selectedModel = selectedModel

        viewModel = BuySelectViewModel<Model>(
            items: items,
            selectedModel: selectedModel
        )
    }

    override func start() -> AnyPublisher<BuySelectCoordinatorResult<Model>, Never> {
        let view = BuySelectView<Model, Cell>(viewModel: viewModel, title: title)
        let viewController = BottomSheetController(title: title, rootView: view)
        viewController.preferredSheetSizing = .fit
        controller.present(viewController, animated: true)

        return Publishers.Merge(
            // Dismiss events
            Publishers.MergeMany(
                viewModel.coordinatorIO.didDissmiss.eraseToAnyPublisher(),
                viewController.deallocatedPublisher().eraseToAnyPublisher()
            )
                .map { BuySelectCoordinatorResult.cancel },
            viewModel.coordinatorIO.didSelectModel.map { BuySelectCoordinatorResult.result(model: $0) }
        ).prefix(1).handleEvents(receiveOutput: { _ in
            viewController.dismiss(animated: true)
        }).eraseToAnyPublisher()
    }
}
