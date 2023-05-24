import Combine
import Foundation

enum ChooseItemCoordinatorResult {
    case item(item: any ChooseItemSearchableItem)
    case cancel
}

class ChooseItemCoordinator<T: ChooseItemRenderable>: Coordinator<ChooseItemCoordinatorResult> {
    let title: String?
    let controller: UIViewController
    let service: any ChooseItemService
    let chosen: (any ChooseItemSearchableItem)?

    init(
        title: String? = nil,
        controller: UIViewController,
        service: any ChooseItemService,
        chosen: (any ChooseItemSearchableItem)?
    ) {
        self.title = title
        self.controller = controller
        self.service = service
        self.chosen = chosen
    }

    override func start() -> AnyPublisher<ChooseItemCoordinatorResult, Never> {
        let wrap = title != nil
        let viewModel = ChooseItemViewModel(
            service: service,
            chosenToken: chosen
        )
        let view = ChooseItemView(viewModel: viewModel) { model in
            (model.item as? T)?.render()
        }
        let aController = KeyboardAvoidingViewController(rootView: view, navigationBarVisibility: wrap ? .visible : .hidden)
        aController.navigationItem.title = title
        controller.show(
            wrap ? UINavigationController(rootViewController: aController) : aController,
            sender: nil
        )

        return Publishers.Merge(
            controller.deallocatedPublisher().map { ChooseItemCoordinatorResult.cancel },
            viewModel.chooseTokenSubject.map { ChooseItemCoordinatorResult.item(item: $0) }
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.controller.dismiss(animated: true)
                })
        ).prefix(1).eraseToAnyPublisher()
    }
}
