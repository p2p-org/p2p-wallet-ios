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
            viewModel?.isLoading = true
            defer {
                viewModel?.isLoading = false
            }
            do {
                try await self?.bankTransfer.verify(OTP: otp)
                self?.numberVerifiedSubject.send(())
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
                try await self.bankTransfer.resendSMS()
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
            Task { [weak self] in
                try await self?.bankTransfer.resendSMS()
            }
        }

        present(controller: controller)

        return Publishers.Merge(
            // Ignore deallocation event if number verified triggered
            Publishers.Merge(
                controller.deallocatedPublisher().map { true },
                numberVerifiedSubject.map { _ in false }
            )
                .prefix(1)
                .filter { $0 }
                .map { _ in StrigaOTPCoordinatorResult.canceled }
                .eraseToAnyPublisher(),
            numberVerifiedSubject
                .flatMap { [unowned self] in
                    self.coordinate(
                        to: StrigaOTPSuccessCoordinator(
                            navigationController: self.viewController
                        )
                    )
                }
                .map { StrigaOTPCoordinatorResult.verified }
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }

    private func increaseTimer(viewModel: EnterSMSCodeViewModel) {
        self.resendCounter = self.resendCounter.incremented()
        viewModel.attemptCounter = Wrapper(self.resendCounter)
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

extension ResendCounter: DefaultsSerializable {}
