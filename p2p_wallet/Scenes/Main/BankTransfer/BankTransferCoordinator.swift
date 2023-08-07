import BankTransfer
import Combine
import CountriesAPI
import Foundation
import Resolver
import UIKit

final class BankTransferCoordinator: Coordinator<Void> {
    @Injected private var bankTransferService: any BankTransferService

    private let viewController: UINavigationController

    init(viewController: UINavigationController) {
        self.viewController = viewController
    }

    enum BankTransferFlowResult {
        case next
        case none
        case completed
    }

    override func start() -> AnyPublisher<Void, Never> {
        bankTransferService.state
            .prefix(1)
            .receive(on: RunLoop.main)
            .flatMap { [unowned self] state in
                coordinator(
                    for: step(userData: state.value),
                    userData: state.value
                ).flatMap { [unowned self] result in
                    switch result {
                    case .next:
                        return coordinate(
                            to: BankTransferCoordinator(viewController: viewController)
                        ).eraseToAnyPublisher()
                    case .none, .completed:
                        return Just(()).eraseToAnyPublisher()
                    }
                }
            }
            .prefix(1)
            .eraseToAnyPublisher()
    }

    private func step(userData: UserData) -> BankTransferStep {
        // registration
        guard userData.userId != nil else {
            return .registration
        }

        // mobile verification
        guard userData.mobileVerified else {
            return .otp
        }

        // kyc
        switch userData.kycStatus {
        case .approved:
            guard let data = userData.wallet?.accounts.eur else { return .kyc }
            return .transfer(data)
        case .onHold, .pendingReview:
            return .kycPendingReview
        case .initiated, .notStarted, .rejected, .rejectedFinal:
            return .kyc
        }
    }

    private func coordinator(for step: BankTransferStep,
                             userData: UserData) -> AnyPublisher<BankTransferFlowResult, Never>
    {
        switch step {
        case .registration:
            return coordinate(
                to: StrigaRegistrationFirstStepCoordinator(navigationController: viewController)
            ).handleEvents(receiveOutput: { [weak self] result in
                guard let self else { return }
                switch result {
                case .completed:
                    self.viewController.setViewControllers(
                        [self.viewController.viewControllers.first!],
                        animated: false
                    )
                case .canceled:
                    break
                }
            }).map { result in
                switch result {
                case .completed:
                    return BankTransferFlowResult.next
                case .canceled:
                    return BankTransferFlowResult.none
                }
            }
            .eraseToAnyPublisher()
        case .otp:
            return coordinate(
                to: StrigaOTPCoordinator(
                    navigationController: viewController,
                    phone: userData.mobileNumber ?? "",
                    verifyHandler: { otp in
                        try await Resolver.resolve((any BankTransferService).self).verify(OTP: otp)
                    },
                    resendHandler: {
                        try await Resolver.resolve((any BankTransferService).self).resendSMS()
                    }
                )
            )
            .flatMap { [unowned self] result in
                switch result {
                case .verified:
                    return coordinate(
                        to: StrigaOTPSuccessCoordinator(
                            navigationController: viewController
                        )
                    )
                    .map { _ in BankTransferFlowResult.next }
                    .eraseToAnyPublisher()
                case .canceled:
                    return Just(BankTransferFlowResult.none)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
        case .kyc:
            return coordinate(
                to: KYCCoordinator(presentingViewController: viewController)
            ).map { result in
                switch result {
                case .pass:
                    return BankTransferFlowResult.next
                case .canceled:
                    return BankTransferFlowResult.none
                }
            }
            .eraseToAnyPublisher()
        case .kycPendingReview:
            return coordinate(
                to: StrigaVerificationPendingSheetCoordinator(presentingViewController: viewController)
            )
            .map { _ in BankTransferFlowResult.none }
            .eraseToAnyPublisher()
        case let .transfer(eurAccount):
            return coordinate(
                to: IBANDetailsCoordinator(navigationController: viewController, eurAccount: eurAccount)
            )
            .map { BankTransferFlowResult.completed }
            .eraseToAnyPublisher()
        }
    }
}

enum BankTransferStep {
    case registration
    case otp
    case kyc
    case kycPendingReview
    case transfer(EURUserAccount)
}
