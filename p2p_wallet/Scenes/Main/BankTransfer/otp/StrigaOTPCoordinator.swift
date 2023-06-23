import BankTransfer
import Combine
import Foundation
import Onboarding
import Resolver
import SwiftyUserDefaults
import KeyAppKitCore

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

    private let resultSubject = PassthroughSubject<StrigaOTPCoordinatorResult, Never>()

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
        controller.navigationItem.largeTitleDisplayMode = .never

        viewModel.coordinatorIO.onConfirm.sinkAsync { [weak self, weak viewModel] otp in
            viewModel?.isLoading = true
            defer {
                viewModel?.isLoading = false
            }
            do {
                try await self?.bankTransfer.verify(OTP: otp)
                self?.numberVerifiedSubject.send(())
                self?.resendCounter = .zero()
            } catch BankTransferError.otpExceededVerification {
                var title = L10n.pleaseWait1DayForTheNextTry
                var subtitle = L10n.after5IncorrectAttemptsWeDisabledSMSVerificationFor1DayToSecureYourAccount
                let errorController = StrigaOTPHardErrorView(
                    title: title,
                    subtitle: subtitle,
                    onAction: {
                        self?.viewController.popToRootViewController(animated: true)
                    }, onSupport: {
                        self?.helpLauncher.launch()
                    }).asViewController(withoutUIKitNavBar: true)
                errorController.hidesBottomBarWhenPushed = true
                self?.viewController.pushViewController(errorController, animated: true)
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
                self.increaseTimer(viewModel: viewModel)
                do {
                    try await self.bankTransfer.resendSMS()
                } catch BankTransferError.otpExceededDailyLimit {
                    self.handleOTPExceededDailyLimitError()
                } catch {
                    viewModel.coordinatorIO.error.send(error)
                }
            }
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.goBack.sinkAsync { [weak self, weak viewModel, unowned controller] in
            viewModel?.isLoading = true
            self?.viewController.showAlert(
                title: L10n.areYouSure,
                message: L10n.youCanConfirmThePhoneNumberAndFinishTheRegistrationLater,
                actions: [
                .init(
                    title: L10n.yesLeftThePage,
                    style: .default,
                    handler: { [weak controller] action in
                        guard let controller else { return }
                        self?.dismiss(controller: controller)
                    }),
                .init(title: L10n.noContinue, style: .cancel)
            ])
            viewModel?.isLoading = false
        }.store(in: &subscriptions)

        if resendCounter.until.timeIntervalSinceNow < 0 {
            // Get initial OTP
            increaseTimer(viewModel: viewModel)
            // Sending the first OTP
            // DISABLED: After createUser, the OTP is automatically sent
//            Task { [weak self] in
//                do {
//                    try await self?.bankTransfer.resendSMS()
//                } catch BankTransferError.otpExceededDailyLimit {
//                    self?.handleOTPExceededDailyLimitError()
//                } catch {
//                    viewModel.coordinatorIO.error.send(error)
//                }
//            }
        }

        present(controller: controller)

        numberVerifiedSubject.flatMap { [unowned self] _ in
            self.coordinate(
                to: StrigaOTPSuccessCoordinator(
                    navigationController: self.viewController
                )
            )
        }.sink { [unowned self] _ in
            self.resultSubject.send(.verified)
        }.store(in: &subscriptions)

        return resultSubject.prefix(1).eraseToAnyPublisher()
    }

    private func increaseTimer(viewModel: EnterSMSCodeViewModel) {
        self.resendCounter = self.resendCounter.incremented()
        viewModel.attemptCounter = Wrapper(self.resendCounter)
    }

    private func handleOTPExceededDailyLimitError() {
        let title = L10n.pleaseWait1DayForTheNextSMSRequest
        let subtitle = L10n.after5SMSRequestsWeDisabledItFor1DayToSecureYourAccount
        let errorController = StrigaOTPHardErrorView(
            title: title,
            subtitle: subtitle,
            onAction: { [weak self] in
                self?.viewController.popToRootViewController(animated: true)
            }, onSupport: { [weak self] in
                self?.helpLauncher.launch()
            }).asViewController(withoutUIKitNavBar: true)
        errorController.hidesBottomBarWhenPushed = true
        self.viewController.pushViewController(errorController, animated: true)
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
        resultSubject.send(.canceled)
    }

}

extension ResendCounter: DefaultsSerializable {}
