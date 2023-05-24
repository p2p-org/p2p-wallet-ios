import Combine
import Foundation

enum ChooseItemCoordinatorResult {
    case item(item: any ChooseItemSearchableItem)
    case cancel
}

class ChooseItemCoordinator<T: ChooseItemRenderable>: Coordinator<ChooseItemCoordinatorResult> {
    let controller: UIViewController
    let service: any ChooseItemService
    let chosen: (any ChooseItemSearchableItem)?

    init(
        controller: UIViewController,
        service: any ChooseItemService,
        chosen: (any ChooseItemSearchableItem)?
    ) {
        self.controller = controller
        self.service = service
        self.chosen = chosen
    }

    override func start() -> AnyPublisher<ChooseItemCoordinatorResult, Never> {
        let viewModel = ChooseItemViewModel(
            service: service,
            chosenToken: chosen
        )
        let view = ChooseItemView(viewModel: viewModel) { model in
            (model.item as? T)?.render()
        }
        let aController = KeyboardAvoidingViewController(rootView: view)
        controller.show(aController, sender: nil)

        return Publishers.Merge(
            controller.deallocatedPublisher().map { ChooseItemCoordinatorResult.cancel },
            viewModel.chooseTokenSubject.map { ChooseItemCoordinatorResult.item(item: $0) }
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.controller.dismiss(animated: true)
                })
        ).prefix(1).eraseToAnyPublisher()
    }
}
