import BankTransfer
import Combine
import Foundation
import Onboarding
import Resolver
import SwiftyUserDefaults

enum StrigaOTPCoordinatorResult {
    case canceled
    case verified
}

final class StrigaOTPCoordinator: Coordinator<StrigaOTPCoordinatorResult> {

    @Injected var bankTransfer: BankTransferService
    @Injected private var helpLauncher: HelpCenterLauncher

    @SwiftyUserDefault(keyPath: \.strigaOTPResendCounter, options: .cached)
    private var resendCounter: ResendCounter

    private var numberVerifiedSubject = PassthroughSubject<Void, Never>()

    private let viewController: UINavigationController
    private let phone: String

    init(viewController: UINavigationController, phone: String) {
        self.viewController = viewController
        self.phone = phone
    }

    override func start() -> AnyPublisher<StrigaOTPCoordinatorResult, Never> {
        let viewModel = EnterSMSCodeViewModel(
            phone: phone,
            attemptCounter: Wrapper(resendCounter),
            strategy: .striga
        )
        let controller = EnterSMSCodeViewController(viewModel: viewModel)
        controller.title = L10n.stepOf(3, 3)
        controller.hidesBottomBarWhenPushed = true

        viewModel.coordinatorIO.onConfirm.sinkAsync { [weak self, weak viewModel] otp in
            guard let self else { return }
            viewModel?.isLoading = true
            defer {
                viewModel?.isLoading = false
            }
            do {
                try await self.bankTransfer.verify(OTP: otp)
                self.numberVerifiedSubject.send(())
            } catch {
                viewModel?.coordinatorIO.error.send(error)
            }
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.showInfo
            .sink(receiveValue: { [weak self] in
                self?.helpLauncher.launch()
            })
            .store(in: &subscriptions)

        viewModel.coordinatorIO.onResend.sinkAsync { [weak self, weak viewModel] process in
            process.start {
                guard let self, let viewModel else { return }
                self.resendCounter = self.resendCounter.incremented()
                viewModel.attemptCounter = Wrapper(self.resendCounter)
                try await self.bankTransfer.resendSMS()
            }
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.goBack.sinkAsync { [weak viewModel] in
            viewModel?.isLoading = true
            self.viewController.showAlert(
                title: L10n.areYouSure,
                message: L10n.youCanConfirmThePhoneNumberAndFinishTheRegistrationLater,
                actions: [
                .init(
                    title: L10n.yesLeftThePage,
                    style: .default,
                    handler: { [weak self, weak controller] action in
                        guard let controller else { return }
                        self?.dismiss(controller: controller)
                    }),
                .init(title: L10n.noContinue, style: .cancel)
            ])
            viewModel?.isLoading = false
        }.store(in: &subscriptions)

        // Get initial OTP
        Task {
            try await self.bankTransfer.resendSMS()
        }

        present(controller: controller)

        return Publishers.Merge(
            controller.deallocatedPublisher()
                .map { StrigaOTPCoordinatorResult.canceled },
            numberVerifiedSubject
                .flatMap {
                    self.coordinate(
                        to: StrigaOTPSuccessCoordinator(
                            navigationController: self.viewController
                        )
                    )
                }
                .map { result in
                    switch result {
                    case .next:
                        return StrigaOTPCoordinatorResult.verified
                    case .cancel:
                        return StrigaOTPCoordinatorResult.canceled
                    }
                }
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }

    private func present(controller: UIViewController) {
        viewController
            .setViewControllers(
                [
                    viewController.viewControllers.first,
                    controller
                ].compactMap { $0 },
                animated: true
            )
    }

    private func dismiss(controller: UIViewController) {
        viewController.popViewController(animated: true)
    }

}
enum StrigaOTPSuccessCoordinatorResult {
    case next
    case cancel
}

final class StrigaOTPSuccessCoordinator: Coordinator<StrigaOTPSuccessCoordinatorResult> {

    @Injected private var helpLauncher: HelpCenterLauncher
    private let nextSubject = PassthroughSubject<Void, Never>()
    private let navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<StrigaOTPSuccessCoordinatorResult, Never> {
        let view = StrigaOTPCompletedView(
            image: .thumbsupImage,
            title: L10n.thankYou,
            subtitle: L10n.TheLastStepIsDocumentAndSelfieVerification.thisIsAOneTimeProcedureToEnsureSafetyOfYourAccount,
            actionTitle: L10n.continue,
            onAction:  { [weak self] in
                self?.nextSubject.send()
            }) { [weak self] in
                self?.helpLauncher.launch()
            }
        let controller = view.asViewController(withoutUIKitNavBar: false)
        controller.navigationItem.hidesBackButton = true
        controller.hidesBottomBarWhenPushed = true
        self.navigationController.setViewControllers([
            navigationController.viewControllers.first,
            controller
        ].compactMap { $0 }, animated: true)

        return Publishers.Merge(
            controller.deallocatedPublisher()
                .map { StrigaOTPSuccessCoordinatorResult.cancel },
            nextSubject
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.navigationController.popViewController(animated: true)
                })
                .map { StrigaOTPSuccessCoordinatorResult.next }
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }
}

extension ResendCounter: DefaultsSerializable {}
