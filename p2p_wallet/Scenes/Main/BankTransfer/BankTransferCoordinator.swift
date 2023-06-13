import BankTransfer
import Combine
import CountriesAPI
import Foundation
import Resolver

enum BankTransferCoordinatorResult {
    case completed
    case canceled
}

final class BankTransferCoordinator: Coordinator<Void> {

    @Injected private var bankTransferService: BankTransferService

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
                return self.coordinator(
                    for: self.step(userData: state.value),
                    userData: state.value
                )
                .flatMap { [unowned self] result in
                    switch result {
                    case .next:
                        return self.coordinate(
                            to: BankTransferCoordinator(viewController: self.viewController)
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
            return .transfer
        case .rejectedFinal:
            return .kycRejected
        case let status where status.isWaitingForUpload:
            return .kyc
        case let status where status.isBeingReviewed:
            return .kycPendingReview
        default:
            // TODO: - Review later
            return .kyc
        }
    }

    private func coordinator(for step: BankTransferStep, userData: UserData) -> AnyPublisher<BankTransferFlowResult, Never> {
        switch step {
        case .registration:
            return coordinate(
                to: BankTransferInfoCoordinator(viewController: viewController)
            ).map { result in
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
                    viewController: viewController,
                    phone: userData.mobileNumber ?? ""
                )
            ).map { result in
                switch result {
                case .verified:
                    return BankTransferFlowResult.next
                case .canceled:
                    return BankTransferFlowResult.none
                }
            }.eraseToAnyPublisher()
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
            let subject = PassthroughSubject<BankTransferFlowResult, Never>()
            viewController.showAlert(
                title: L10n.yourDocumentsVerificationIsPending,
                message: L10n.usuallyItTakesAFewHours,
                actions: [
                    .init(
                        title: L10n.ok,
                        style: .default,
                        handler: { [weak subject] action in
                            subject?.send(.none)
                        }
                    )
                ]
            )
            return subject.prefix(1).eraseToAnyPublisher()
        case .kycRejected:
            let subject = PassthroughSubject<BankTransferFlowResult, Never>()
            viewController.showAlert(
                title: L10n.verificationIsRejected,
                message: L10n.sorryBankTransferIsUnavailableForYou,
                actions: [
                    .init(
                        title: L10n.okay,
                        style: .default,
                        handler: { [weak subject] action in
                            subject?.send(.none)
                        }
                    ),
                    .init(
                        title: "Appeal",
                        style: .default,
                        handler: { [weak subject] action in
                            subject?.send(.none)
                        }
                    )
                ]
            )
            return subject.prefix(1).eraseToAnyPublisher()
        case .transfer:
            return coordinate(
                to: StrigaTransferCoordinator(
                    navigation: viewController
                )
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
    case kycRejected
    case transfer
}
