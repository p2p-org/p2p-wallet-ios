import Combine
import SwiftUI

struct StartParameters {
    let isAnimatable: Bool
}

final class StartCoordinator: Coordinator<Void> {
    private let window: UIWindow
    private weak var viewController: UIViewController?
    private let params: StartParameters
    private var subject = PassthroughSubject<Void, Never>()

    // MARK: - Initializer

    init(window: UIWindow, params: StartParameters = StartParameters(isAnimatable: true)) {
        self.window = window
        self.params = params
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StartViewModel(isAnimatable: params.isAnimatable)
        let viewController = UIHostingController(rootView: StartView(viewModel: viewModel))
        self.viewController = viewController

        let navigationController = UINavigationController(rootViewController: viewController)
        style(nc: navigationController)
        window.animate(newRootViewController: navigationController)

        viewModel.$navigatableScene.sink { [weak self] scene in
            guard let self = self, let scene = scene else { return }
            switch scene {
            case .restoreWallet:
                self.openRestoreWallet(vc: viewController)
            case .createWallet:
                self.openCreateWallet(vc: viewController)
            case .openTerms:
                self.openTerms()
            case .mockContinue:
                self.openContinue(vc: viewController)
            }
        }.store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openCreateWallet(vc: UIViewController) {
        coordinate(to: CreateWalletCoordinator(parent: vc))
            .sink { _ in }.store(in: &subscriptions)
    }

    private func openRestoreWallet(vc: UIViewController) {
        coordinate(to: RestoreWalletCoordinator(parent: vc))
            .sink { _ in }.store(in: &subscriptions)
    }

    private func openTerms() {
        let vc = WLMarkdownVC(
            title: L10n.termsOfUse,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        viewController?.present(vc, animated: true)
    }

    // TODO: Mock method
    private func openContinue(vc _: UIViewController) {
        coordinate(to: ContinueCoordinator(window: window))
            .sink(receiveValue: {}).store(in: &subscriptions)
    }

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.shadowImage = UIImage()
        nc.navigationBar.isTranslucent = true
    }
}
