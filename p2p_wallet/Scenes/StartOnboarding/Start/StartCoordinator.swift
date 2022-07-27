import Combine
import SwiftUI

enum StartCoordinatorNavigation {
    case root(window: UIWindow)
    case push(nc: UINavigationController)
}

final class StartCoordinator: Coordinator<Void> {
    private let navigation: StartCoordinatorNavigation
    private weak var viewController: UIViewController?

    private var subject = PassthroughSubject<Void, Never>() // TODO: - Complete this when next navigation is done

    // MARK: - Initializer

    init(navigation: StartCoordinatorNavigation) {
        self.navigation = navigation
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StartViewModel()
        let viewController = UIHostingController(rootView: StartView(viewModel: viewModel))
        self.viewController = viewController

        switch navigation {
        case let .root(window):
            let navigationController = UINavigationController(rootViewController: viewController)
            style(nc: navigationController)
            window.rootViewController = navigationController
        case let .push(nc):
            nc.delegate = self
            nc.pushViewController(viewController, animated: true)
        }

        viewModel.navigation.action.sink { [weak self] scene in
            guard let self = self else { return }
            switch scene {
            case .openTerms:
                self.openTerms(on: viewController)
            case .restoreWallet:
                // TODO: - Add restoration handler
                self.temproraryOpenContinueForTesting()
            case .createWallet:
                self.openCreateWallet(nc: viewController.navigationController)
            }
        }.store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openTerms(on vc: UIViewController) {
        let termsVC = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        vc.present(termsVC, animated: true)
    }

    private func openCreateWallet(nc: UINavigationController?) {
        coordinate(to: CreateWalletCoordinator(tKeyFacade: nil, navigationController: nc))
            .sink { _ in }.store(in: &subscriptions)
    }

    private func temproraryOpenContinueForTesting() { // must be deleted after wallet restoration is done
        switch navigation {
        case let .root(window):
            coordinate(to: ContinueCoordinator(window: window)).sink { _ in }.store(in: &subscriptions)
        case let .push(nc):
            break
        }
    }

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.shadowImage = UIImage()
        nc.navigationBar.isTranslucent = true
        nc.navigationBar.tintColor = .h5887ff
    }
}

// MARK: - UINavigationControllerDelegate

extension StartCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated _: Bool
    ) {
        guard let currentVC = self.viewController, viewController != currentVC else { return }
        if navigationController.viewControllers.contains(where: { $0 == currentVC }) == false {
            subject.send(completion: .finished)
        }
    }
}
