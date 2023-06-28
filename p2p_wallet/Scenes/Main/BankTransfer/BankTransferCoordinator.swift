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
            guard let data = userData.wallets.first?.accounts.eur else { return .kyc }
            return .transfer(data)
        case .onHold, .pendingReview:
            return .kycPendingReview
        case .initiated, .notStarted, .rejected, .rejectedFinal:
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
            return coordinate(
                to: StrigaVerificationPendingSheetCoordinator(presentingViewController: viewController)
            )
            .map { _ in return BankTransferFlowResult.none }
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
    case transfer(UserEURAccount)
}
