import Combine
import Onboarding
import Resolver
import SwiftUI

final class ContinueCoordinator: Coordinator<OnboardingWallet> {
    private let window: UIWindow

    private var subject = PassthroughSubject<OnboardingWallet, Never>()

    @Injected private var onboardingService: OnboardingService

    // MARK: - Initializer

    init(window: UIWindow) {
        self.window = window
    }

    override func start() -> AnyPublisher<OnboardingWallet, Never> {
        guard let lastState = onboardingService.lastState else {
            return Empty(completeImmediately: true).eraseToAnyPublisher()
        }

        let viewModel = ContinueViewModel(subtitle: lastState.subtitle)
        let view = ContinueView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let navigationController = UINavigationController(rootViewController: viewController)
        style(nc: navigationController)
        window.animate(newRootViewController: navigationController)

        viewModel.startDidTap.sink { [weak self] _ in
            self?.openStart(navigationController: navigationController)
        }
        .store(in: &subscriptions)

        viewModel.continueDidTap.sink { [weak self] _ in
            self?.continueCreateWallet()
        }
        .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openStart(navigationController _: UINavigationController) {
        onboardingService.lastState = nil

        coordinate(to: StartCoordinator(window: window, params: StartParameters(isAnimatable: false)))
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)
    }

    private func continueCreateWallet() {
        guard
            let lastState = onboardingService.lastState,
            let root = window.rootViewController
        else { return }

        coordinate(to: CreateWalletCoordinator(parent: root, initialState: lastState))
            .sink { result in
                switch result {
                case let .success(onboardingWallet):
                    self.subject.send(onboardingWallet)
                default:
                    break
                }
                self.subject.send(completion: .finished)
            }.store(in: &subscriptions)
    }

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.shadowImage = UIImage()
        nc.navigationBar.isTranslucent = true
    }
}

private extension CreateWalletFlowState {
    var email: String {
        switch self {
        case let .bindingPhoneNumber(email, _, _, _, _):
            return email
        case let .securitySetup(email, _, _, _, _):
            return email
        default:
            return "?"
        }
    }

    var subtitle: String {
        let email = self.email
        switch self {
        case .bindingPhoneNumber:
            return L10n.YouHaveAGreatStartWith.itSOnlyAPhoneNumberNeededToCreateANewWallet(email)
        case .securitySetup:
            return L10n.YouHaveAGreatStartWith.itSOnlyAPinCodeNeededToCreateANewWallet(email)
        default:
            return ""
        }
    }
}
