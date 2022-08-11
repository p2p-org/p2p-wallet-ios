import Combine
import SwiftUI

final class ContinueCoordinator: Coordinator<Void> {
    private let window: UIWindow

    private var subject = PassthroughSubject<Void, Never>()

    // MARK: - Initializer

    init(window: UIWindow) {
        self.window = window
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = ContinueViewModel()
        let view = ContinueView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let navigationController = UINavigationController(rootViewController: viewController)
        style(nc: navigationController)
        window.animate(newRootViewController: navigationController)

        viewModel.startDidTap.sink { [weak self] _ in
            self?.openStart(navigationController: navigationController)
        }
        .store(in: &subscriptions)

        viewModel.continueDidTap.sink { _ in
            // TODO: Add continue navigation
        }
        .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openStart(navigationController _: UINavigationController) {
        coordinate(to: StartCoordinator(window: window, params: StartParameters(isAnimatable: false)))
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)
    }

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.shadowImage = UIImage()
        nc.navigationBar.isTranslucent = true
    }
}
