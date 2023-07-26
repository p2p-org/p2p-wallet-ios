import BankTransfer
import Combine
import Foundation
import Onboarding
import Resolver
import SwiftyUserDefaults
import KeyAppKitCore
import UIKit
import Reachability

enum StrigaOTPCoordinatorResult {
    case canceled
    case verified
}

enum StrigaOTPNavigation {
    case `default`
    case nextToRoot
}

final class StrigaOTPCoordinator: Coordinator<StrigaOTPCoordinatorResult> {

    // MARK: - Dependencies

    @Injected private var helpLauncher: HelpCenterLauncher
    @Injected private var reachability: Reachability

    // MARK: - Properties

    @SwiftyUserDefault(keyPath: \.strigaOTPResendCounter, options: .cached)
    private var resendCounter: ResendCounter?
    @SwiftyUserDefault(keyPath: \.strigaOTPConfirmErrorDate, options: .cached)
    private var lastConfirmErrorData: Date?
    @SwiftyUserDefault(keyPath: \.strigaOTPResendErrorDate, options: .cached)
    private var lastResendErrorDate: Date?

    private let resultSubject = PassthroughSubject<StrigaOTPCoordinatorResult, Never>()

    private let navigationController: UINavigationController
    private let phone: String
    private let navigation: StrigaOTPNavigation
    /// Injectable verify opt request
    private let verifyHandler: (String) async throws -> Void

    /// Injectable resend opt request
    private let resendHandler: () async throws -> Void

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        phone: String,
        navigation: StrigaOTPNavigation = .default,
        verifyHandler: @escaping (String) async throws -> Void,
        resendHandler: @escaping () async throws -> Void
    ) {
        self.navigationController = navigationController
        self.phone = phone
        self.navigation = navigation
        self.verifyHandler = verifyHandler
        self.resendHandler = resendHandler
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<StrigaOTPCoordinatorResult, Never> {
        // Initialize timer
        var timerHasJustInitialized = false
        if self.resendCounter == nil {
            self.resendCounter = .zero()
            timerHasJustInitialized = true
        }

        // Create viewModel
        let viewModel = EnterSMSCodeViewModel(
            phone: phone,
            attemptCounter: Wrapper(resendCounter ?? .zero()),
            strategy: .striga
        )
        // Create viewController
        let controller = EnterSMSCodeViewController(viewModel: viewModel)
        controller.title = L10n.stepOf(3, 3)
        controller.hidesBottomBarWhenPushed = true
        controller.navigationItem.largeTitleDisplayMode = .never

        // Handle on confirm
        viewModel.coordinatorIO.onConfirm
            .sinkAsync { [weak self, weak viewModel] otp in
                viewModel?.isLoading = true
                defer {
                    viewModel?.isLoading = false
                }
                do {
                    try await self?.verifyHandler(otp)
                    self?.resendCounter = nil
                    self?.resultSubject.send(.verified)
                } catch BankTransferError.otpExceededVerification {
                    self?.lastConfirmErrorData = Date().addingTimeInterval(60 * 60 * 24)
                    self?.handleOTPConfirmLimitError()
                    await self?.logAlertMessage(error: BankTransferError.otpExceededVerification)
                } catch BankTransferError.otpInvalidCode {
                    viewModel?.coordinatorIO.error.send(APIGatewayError.invalidOTP)
                    await self?.logAlertMessage(error: BankTransferError.otpInvalidCode)
                } catch {
                    viewModel?.coordinatorIO.error.send(error)
                    await self?.logAlertMessage(error: error)
                }
            }
            .store(in: &subscriptions)

        // Handle show info
        viewModel.coordinatorIO.showInfo
            .sink(receiveValue: { [weak self] in
                self?.helpLauncher.launch()
            })
            .store(in: &subscriptions)

        // Handle on resend
        viewModel.coordinatorIO.onResend
            .sinkAsync { [weak self, weak viewModel] process in
                process.start {
                    guard let self, let viewModel else { return }
                    await self.resendSMS(viewModel: viewModel, increaseTimer: !timerHasJustInitialized)
                    timerHasJustInitialized = false
                }
            }
            .store(in: &subscriptions)

        // Handle going back
        viewModel.coordinatorIO.goBack
            .sinkAsync { [weak self, weak viewModel, unowned controller] in
                viewModel?.isLoading = true
                self?.navigationController.showAlert(
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
            }
            .store(in: &subscriptions)

        // Handle initial event
        if let lastResendErrorDate, lastResendErrorDate.timeIntervalSinceNow > 0 {
            handleOTPExceededDailyLimitError()
        } else if let lastConfirmErrorData, lastConfirmErrorData.timeIntervalSinceNow > 0 {
            handleOTPConfirmLimitError()
        } else {
            _ = reachability.check()
            present(controller: controller)

            if timerHasJustInitialized || resendCounter?.until.timeIntervalSinceNow < 0 {
                // Send request only if lastResendErrorDate and lastConfirmErrorData are nil
                // Resend OTP explicitly if timer is off (it cand be also launched on previous screen)
                viewModel.resendButtonTapped()
            }
        }

        return resultSubject.prefix(1).eraseToAnyPublisher()
    }

    private func resendSMS(viewModel: EnterSMSCodeViewModel, increaseTimer: Bool) async {
        if increaseTimer {
            self.increaseTimer(viewModel: viewModel)
        }

        do {
            try await self.resendHandler()
        } catch BankTransferError.otpExceededDailyLimit {
            self.handleOTPExceededDailyLimitError()
            self.lastResendErrorDate = Date().addingTimeInterval(60 * 60 * 24)
            await self.logAlertMessage(error: BankTransferError.otpExceededDailyLimit)
        } catch {
            viewModel.coordinatorIO.error.send(error)
            await self.logAlertMessage(error: error)
        }
    }

    private func increaseTimer(viewModel: EnterSMSCodeViewModel) {
        self.resendCounter = resendCounter?.incremented()
        if let resendCounter {
            viewModel.attemptCounter = Wrapper(resendCounter)
        }
    }

    private func handleOTPExceededDailyLimitError() {
        let title = L10n.pleaseWait1DayForTheNextSMSRequest
        let subtitle = L10n.after5SMSRequestsWeDisabledItFor1DayToSecureYourAccount
        let errorController = StrigaOTPHardErrorView(
            title: title,
            subtitle: subtitle,
            onAction: { [weak self] in
                self?.navigationController.popToRootViewController(animated: true)
                self?.resultSubject.send(.canceled)
            }, onSupport: { [weak self] in
                self?.helpLauncher.launch()
            }).asViewController(withoutUIKitNavBar: true)
        errorController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(errorController, animated: true)
    }

    private func handleOTPConfirmLimitError() {
        let title = L10n.pleaseWait1DayForTheNextTry
        let subtitle = L10n.after5IncorrectAttemptsWeDisabledSMSVerificationFor1DayToSecureYourAccount
        let errorController = StrigaOTPHardErrorView(
            title: title,
            subtitle: subtitle,
            onAction: { [weak self] in
                self?.navigationController.popToRootViewController(animated: true)
                self?.resultSubject.send(.canceled)
            }, onSupport: { [weak self] in
                self?.helpLauncher.launch()
            }).asViewController(withoutUIKitNavBar: true)
        errorController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(errorController, animated: true)
    }

    private func present(controller: UIViewController) {
        switch navigation {
        case .default:
            navigationController.pushViewController(controller, animated: true)
        case .nextToRoot:
            navigationController.setViewControllers([navigationController.viewControllers.first!, controller], animated: true)
        }
    }

    private func dismiss(controller: UIViewController) {
        navigationController.popViewController(animated: true)
        resultSubject.send(.canceled)
    }

    private func logAlertMessage(error: Error) async {
        let loggerData = await AlertLoggerDataBuilder.buildLoggerData(error: error)
        
        DefaultLogManager.shared.log(
            event: "Striga Registration iOS Alarm",
            logLevel: .alert,
            data: StrigaRegistrationAlertLoggerMessage(
                userPubkey: loggerData.userPubkey,
                platform: loggerData.platform,
                appVersion: loggerData.appVersion,
                timestamp: loggerData.timestamp,
                error: .init(
                    source: "striga api",
                    kycSDKState: "initial",
                    error: loggerData.otherError ?? ""
                )
            )
        )
    }
}

extension ResendCounter: DefaultsSerializable {}
