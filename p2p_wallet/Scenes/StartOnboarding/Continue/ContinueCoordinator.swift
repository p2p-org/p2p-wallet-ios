import Combine
import Onboarding
import Resolver
import SwiftUI

final class ContinueCoordinator: Coordinator<OnboardingResult> {
    private let window: UIWindow
    private let navigationController: OnboardingNavigationController

    private var subject = PassthroughSubject<OnboardingResult, Never>()

    @Injected private var onboardingService: OnboardingService

    // MARK: - Initializer

    init(window: UIWindow) {
        self.window = window
        navigationController = OnboardingNavigationController()
    }

    override func start() -> AnyPublisher<OnboardingResult, Never> {
        guard let lastState = onboardingService.lastState else {
            return Empty(completeImmediately: true).eraseToAnyPublisher()
        }

        let viewModel = ContinueViewModel(subtitle: lastState.subtitle)
        let view = ContinueView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        window.animate(newRootViewController: viewController)

        viewModel.startDidTap.sink { [weak self] _ in
            self?.openStart()
        }
        .store(in: &subscriptions)

        viewModel.continueDidTap.sink { [weak self] _ in
            self?.continueCreateWallet(animated: true)
        }
        .store(in: &subscriptions)

        // Force continue in predefined states
        switch onboardingService.lastState {
        case .securitySetup:
            continueCreateWallet(animated: false)
        default:
            break
        }

        return subject.eraseToAnyPublisher()
    }

    private func openStart() {
        coordinate(to: StartCoordinator(window: window, params: StartParameters(isAnimatable: false)))
            .sink(receiveValue: { result in
                self.subject.send(result)
                self.subject.send(completion: .finished)
            })
            .store(in: &subscriptions)
    }

    private func continueCreateWallet(animated: Bool) {
        guard
            let lastState = onboardingService.lastState,
            let root = window.rootViewController
        else { return }

        coordinate(to: CreateWalletCoordinator(
            parent: root,
            navigationController: navigationController,
            initialState: lastState,
            animated: animated
        ))
            .sink { result in
                switch result {
                case let .success(onboardingWallet):
                    self.subject.send(.created(onboardingWallet))
                default:
                    break
                }
                self.subject.send(completion: .finished)
            }.store(in: &subscriptions)
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
            return L10n.YouHaveAGreatStartWith.onlyAPhoneNumberIsNeededToCreateANewWallet(email)
        case .securitySetup:
            return L10n.YouHaveAGreatStartWith.itSOnlyAPinCodeNeededToCreateANewWallet(email)
        default:
            return ""
        }
    }
}
