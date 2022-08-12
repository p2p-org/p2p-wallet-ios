import Combine
import Onboarding
import SwiftUI

struct StartParameters {
    let isAnimatable: Bool
}

final class StartCoordinator: Coordinator<OnboardingWallet> {
    private let window: UIWindow
    private weak var viewController: UIViewController?
    private let params: StartParameters
    private var subject = PassthroughSubject<OnboardingWallet, Never>()

    // MARK: - Initializer

    init(window: UIWindow, params: StartParameters = StartParameters(isAnimatable: true)) {
        self.window = window
        self.params = params
    }

    override func start() -> AnyPublisher<OnboardingWallet, Never> {
        let viewModel = StartViewModel(isAnimatable: params.isAnimatable)
        let viewController = UIHostingController(rootView: StartView(viewModel: viewModel))
        self.viewController = viewController

        let navigationController = UINavigationController(rootViewController: viewController)
        style(nc: navigationController)
        window.animate(newRootViewController: navigationController)

        viewModel.createWalletDidTap
            .sink { [weak self] _ in
                self?.openCreateWallet(vc: viewController)
            }
            .store(in: &subscriptions)

        viewModel.restoreWalletDidTap
            .sink { [weak self] _ in
                self?.openRestoreWallet(vc: viewController)
            }
            .store(in: &subscriptions)

        viewModel.termsDidTap
            .sink { [weak self] _ in
                self?.openTerms()
            }
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openCreateWallet(vc: UIViewController) {
        coordinate(to: CreateWalletCoordinator(parent: vc)).sink { [weak vc] result in
            switch result {
            case let .restore(socialProvider, email):
                guard let vc = vc else { return }
                self.openRestoreWallet(vc: vc)
            case let .success(onboardingWallet):
                self.subject.send(onboardingWallet)
            }
            self.subject.send(completion: .finished)
        }.store(in: &subscriptions)
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

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.shadowImage = UIImage()
        nc.navigationBar.isTranslucent = true
    }
}
