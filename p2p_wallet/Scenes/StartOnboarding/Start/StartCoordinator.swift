import Combine
import SwiftUI

enum StartCoordinatorNavigation {
    case root(window: UIWindow)
    case push(nc: UINavigationController)
}

final class StartCoordinator: Coordinator<Void> {
    private let navigation: StartCoordinatorNavigation

    private var subject = PassthroughSubject<Void, Never>() // TODO: - Complete this when next navigation is done

    // MARK: - Initializer

    init(navigation: StartCoordinatorNavigation) {
        self.navigation = navigation
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StartViewModel()

        let view = StartView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        switch navigation {
        case let .root(window):
            let navigationController = UINavigationController(rootViewController: viewController)
            window.rootViewController = navigationController
        case let .push(nc):
            nc.pushViewController(viewController, animated: true)
        }

        viewModel.$result.sink { [weak self] value in
            guard let self = self else { return }

            switch value {
            case .openTerms:
                self.openTerms(on: viewController)
            case .restoreWallet: // TODO: - Add restoration handler
                self.temproraryOpenContinueForTesting()
            case .createWallet:
                self
                    .coordinate(to: CreateWalletCoordinator(tKeyFacade: nil,
                                                            navigationController: viewController.navigationController))
                    .sink { _ in }.store(in: &self.subscriptions)
            case .none:
                break
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

    private func temproraryOpenContinueForTesting() {
        switch navigation {
        case let .root(window):
            coordinate(to: ContinueCoordinator(window: window)).sink { _ in }.store(in: &subscriptions)
        case let .push(nc):
            break
        }
    }
}
