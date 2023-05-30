import BankTransfer
import Combine
import Foundation
import Onboarding
import Resolver

enum StrigaOTPCoordinatorResult {
    case cancel
    case verified
}

final class StrigaOTPCoordinator: Coordinator<StrigaOTPCoordinatorResult> {

    @Injected var bankTransfer: BankTransferService
    @Injected private var helpLauncher: HelpCenterLauncher

    @UserDefault(key: "striga_otp_resendCounter", defaultValue: Wrapper<ResendCounter>(ResendCounter.zero()))
    private var resendCounter: Wrapper<ResendCounter>

    private var resultSubject = PassthroughSubject<Bool, Never>()

    let viewController: UIViewController
    let phone: String

    init(viewController: UIViewController, phone: String) {
        self.viewController = viewController
        self.phone = phone
    }

    override func start() -> AnyPublisher<StrigaOTPCoordinatorResult, Never> {
        let viewModel = EnterSMSCodeViewModel(
            phone: phone,
            attemptCounter: resendCounter,
            strategy: .striga
        )
        let controller = EnterSMSCodeViewController(viewModel: viewModel)
        controller.title = L10n.stepOf(3, 3)

        viewModel.coordinatorIO.onConfirm.sinkAsync { [weak self, weak viewModel] otp in
            viewModel?.isLoading = true
            do {
                let result = try await self?.bankTransfer.verify(OTP: otp)
                if result == false {
                    viewModel?.coordinatorIO.error.send(APIGatewayError.invalidOTP)
                }
            } catch {
                viewModel?.coordinatorIO.error.send(error)
            }
            viewModel?.isLoading = false
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.showInfo
            .sink(receiveValue: { [weak self] in
                self?.helpLauncher.launch()
            })
            .store(in: &subscriptions)

        viewModel.coordinatorIO.onResend.sinkAsync { [weak self, weak viewModel] process in
            process.start {
                guard let self, let viewModel else { return }
                viewModel.attemptCounter = Wrapper(viewModel.attemptCounter.value.incremented())
                try await self.bankTransfer.getOTP()
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
            try await self.bankTransfer.getOTP()
        }

        present(controller: controller)

        return Publishers.Merge(
            controller.deallocatedPublisher().map { StrigaOTPCoordinatorResult.cancel },
            resultSubject.filter { $0 }.map { _ in StrigaOTPCoordinatorResult.verified }
        ).prefix(1).eraseToAnyPublisher()
    }

    private func present(controller: UIViewController) {
        if let navigation = self.viewController as? UINavigationController {
            navigation.pushViewController(controller, animated: true, completion: {})
        } else {
            self.viewController.present(controller, animated: true)
        }
    }

    private func dismiss(controller: UIViewController) {
        if let navigation = self.viewController as? UINavigationController {
            navigation.popViewController(animated: true)
        } else {
            controller.dismiss(animated: true)
        }
    }

}
