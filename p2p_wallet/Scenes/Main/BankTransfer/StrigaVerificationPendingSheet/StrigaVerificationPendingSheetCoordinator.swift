import Combine

final class StrigaVerificationPendingSheetCoordinator: Coordinator<Void> {
    private let presentingViewController: UIViewController

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = StrigaVerificationPendingSheetView { [weak self] in
            self?.presentingViewController.dismiss(animated: true)
        }

        let controller = UIBottomSheetHostingController(
            rootView: view,
            ignoresKeyboard: true
        )

        controller.view.layer.cornerRadius = 20
        presentingViewController.present(controller, interactiveDismissalType: .standard)

        return controller.deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
