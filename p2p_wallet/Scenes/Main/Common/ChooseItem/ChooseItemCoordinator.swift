import Combine
import Foundation

enum ChooseItemCoordinatorResult {
    case item(item: any ChooseItemSearchableItem)
    case cancel
}

final class ChooseItemCoordinator<T: ChooseItemRenderable>: Coordinator<ChooseItemCoordinatorResult> {
    private let title: String?
    private let controller: UIViewController
    private let service: any ChooseItemService
    private let chosen: (any ChooseItemSearchableItem)?
    private let showDoneButton: Bool
    private let isSearchEnabled: Bool
    private weak var viewController: UIViewController?

    init(
        title: String? = nil,
        controller: UIViewController,
        service: any ChooseItemService,
        chosen: (any ChooseItemSearchableItem)?,
        showDoneButton: Bool = false,
        isSearchEnabled: Bool = true
    ) {
        self.title = title
        self.controller = controller
        self.service = service
        self.chosen = chosen
        self.showDoneButton = showDoneButton
        self.isSearchEnabled = isSearchEnabled
    }

    override func start() -> AnyPublisher<ChooseItemCoordinatorResult, Never> {
        let isWrapped = controller is UINavigationController
        let viewModel = ChooseItemViewModel(
            service: service,
            chosenItem: chosen,
            isSearchEnabled: isSearchEnabled
        )
        let view = ChooseItemView(viewModel: viewModel) { model in
            (model.item as? T)?.render()
        }
        let aController = KeyboardAvoidingViewController(rootView: view)
        aController.navigationItem.title = title
        controller.show(
            isWrapped ? aController : UINavigationController(rootViewController: aController),
            sender: nil
        )
        if showDoneButton {
            aController.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: L10n.done,
                style: .plain,
                target: self,
                action: #selector(dismiss)
            )
        }

        viewController = aController
        return Publishers.Merge(
            controller.deallocatedPublisher().map { ChooseItemCoordinatorResult.cancel },
            viewModel.chooseTokenSubject.map { ChooseItemCoordinatorResult.item(item: $0) }
                .handleEvents(receiveOutput: { [weak self] _ in
                    isWrapped ? (self?.controller as? UINavigationController)?.popViewController(animated: true, completion: { }) : self?.controller.dismiss(animated: true)
                })
        ).prefix(1).eraseToAnyPublisher()
    }

    @objc func dismiss() {
        // Dismiss since Done shouldn't be displayed on navigation?
        viewController?.dismiss(animated: true)
    }
}
