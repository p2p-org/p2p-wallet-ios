import Combine
import Onboarding
import Resolver
import SwiftUI

final class SolendTutorialCoordinator: Coordinator<Void> {
    /// viewController that presents this tutorial
    private weak var viewController: UIViewController
    /// subject that handle releasing coordinator
    private var subject = PassthroughSubject<Void, Never>()

    // MARK: - Initializer

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = SolendTutorialViewModel()
        let presentingViewController = UIHostingController(rootView: SolendTutorialView(viewModel: viewModel))
        presentingViewController.modalPresentationStyle = .fullScreen
        viewController.present(presentingViewController, animated: true)

        viewModel.skipDidTap
            .sink { [weak presentingViewController] _ in
                presentingViewController?.dismiss(animated: true) { [weak self] in
                    self.subject.send(completion: .finished)
                }
            }
            .store(in: &subscriptions)

        viewModel.continueDidTap
            .sink { [weak self] _ in
                // FIXME: - fix later
                presentingViewController?.dismiss(animated: true) { [weak self] in
                    self.subject.send(completion: .finished)
                }
            }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }
}
