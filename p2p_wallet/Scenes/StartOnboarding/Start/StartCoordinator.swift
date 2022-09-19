import Combine
import Onboarding
import Resolver
import SwiftUI

struct StartParameters {
    let isAnimatable: Bool
}

enum OnboardingResult {
    case created(CreateWalletData)
    case restored(RestoreWalletData)
    case breakProcess
}

final class StartCoordinator: Coordinator<OnboardingResult> {
    private let window: UIWindow
    private weak var viewController: UIViewController?
    private let params: StartParameters
    private var subject = PassthroughSubject<OnboardingResult, Never>()
    private let navigationController: OnboardingNavigationController

    // MARK: - Initializer

    init(window: UIWindow, params: StartParameters = StartParameters(isAnimatable: true)) {
        self.window = window
        self.params = params
        navigationController = OnboardingNavigationController()
    }

    override func start() -> AnyPublisher<OnboardingResult, Never> {
        let viewModel = StartViewModel(isAnimatable: params.isAnimatable)
        let viewController = UIHostingController(rootView: StartView(viewModel: viewModel))
        self.viewController = viewController
        window.animate(newRootViewController: viewController)

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
        let service: OnboardingService = Resolver.resolve()

        let onFinish = { [weak vc] (result: CreateWalletResult) in
            switch result {
            case .restore:
                guard let vc = vc else { return }
                self.openRestoreWallet(vc: vc)
            case let .success(data):
                self.subject.send(.created(data))
                self.subject.send(completion: .finished)
            }
        }

        if let lastState = service.lastState {
            switch lastState {
            case let .bindingPhoneNumber(email, seedPhrase, ethPublicKey, deviceShare, innerState):
                switch innerState {
                case let .block(until, _, phoneNumber, data):
                    // Move user to block screen, after expired time move him to enter phone number
                    if Date() < until {
                        coordinate(to: CreateWalletCoordinator(
                            parent: vc,
                            navigationController: navigationController,
                            initialState: CreateWalletFlowState.bindingPhoneNumber(
                                email: email,
                                seedPhrase: seedPhrase,
                                ethPublicKey: ethPublicKey,
                                deviceShare: deviceShare,
                                BindingPhoneNumberState
                                    .block(
                                        until: until,
                                        reason: .blockEnterPhoneNumber,
                                        phoneNumber: phoneNumber,
                                        data: data
                                    )
                            )
                        ))
                            .sink(receiveValue: onFinish)
                            .store(in: &subscriptions)

                        return
                    } else {
                        // Open continuation
                        coordinate(to: ContinueCoordinator(window: window))
                            .sink { result in
                                self.subject.send(result)
                                self.subject.send(completion: .finished)
                            }.store(in: &subscriptions)

                        return
                    }
                default: break
                }
            default: break
            }
        }

        coordinate(to: CreateWalletCoordinator(parent: vc, navigationController: navigationController))
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .restore:
                    self.openRestoreWallet(vc: vc)
                case let .success(data):
                    self.subject.send(.created(data))
                    self.subject.send(completion: .finished)
                }
            }.store(in: &subscriptions)
    }

    private func openRestoreWallet(vc: UIViewController) {
        coordinate(to: RestoreWalletCoordinator(navigation: .child(
            parent: vc,
            navigationController: navigationController
        ))).sink(receiveValue: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .restored(data):
                self.subject.send(.restored(data))
                self.subject.send(completion: .finished)
            case .created, .breakProcess: break
            }
        }).store(in: &subscriptions)
    }

    private func openTerms() {
        let vc = WLMarkdownVC(
            title: L10n.termsOfUse,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        viewController?.present(vc, animated: true)
    }
}
