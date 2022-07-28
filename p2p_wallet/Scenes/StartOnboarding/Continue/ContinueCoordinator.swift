import Combine
import SwiftUI

final class ContinueCoordinator: Coordinator<Void> {
    private let window: UIWindow

    private var subject = PassthroughSubject<Void, Never>() // TODO: - Complete this when next navigation is done

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

        viewModel.navigation.action.sink { [weak self] scene in
            guard let self = self else { return }
            switch scene {
            case .continue:
                break
            case .start:
                self.openStart(navigationController: navigationController)
            }
        }.store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openStart(navigationController: UINavigationController) {
        coordinate(to: StartCoordinator(navigation: .push(nc: navigationController)))
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)
    }

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.shadowImage = UIImage()
        nc.navigationBar.isTranslucent = true
    }
}
