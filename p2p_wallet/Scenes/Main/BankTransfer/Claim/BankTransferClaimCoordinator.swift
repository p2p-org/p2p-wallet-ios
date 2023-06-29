import Foundation
import UIKit
import BankTransfer
import Resolver
import Combine

/// Result for `BankTransferClaimCoordinator`
enum BankTransferClaimCoordinatorResult {
    /// Transaction has been successfully created
    case completed
    /// Transaction has been cancelled
    case canceled
}

/// Coordinator that controlls claim operation
final class BankTransferClaimCoordinator: Coordinator<BankTransferClaimCoordinatorResult> {

    // MARK: - Dependencies

    @Injected private var bankTransferService: BankTransferService

    // MARK: - Properties

    private let navigationController: UINavigationController
    

    // MARK: - Initialization

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<BankTransferClaimCoordinatorResult, Never> {
        // Start OTP Coordinator
        bankTransferService.state
            .flatMap { [unowned self] state in
                guard let phone = state.value.mobileNumber else {
                    return Just(BankTransferClaimCoordinatorResult.canceled)
                        .eraseToAnyPublisher()
                }
                
                return coordinate(
                    to: StrigaOTPCoordinator(
                        viewController: navigationController,
                        phone: phone,
                        verifyHandler: { [unowned self] otp in
                            // TODO: - Verify otp
//                            try await bankTransferService.transactionVeri
                        },
                        resendHandler: { [unowned self] in
                            // TODO: - Resend sms
                        }
                    )
                )
                    .map { result in
                        switch result {
                        case .verified:
                            // TODO: - Logics here
                            return BankTransferClaimCoordinatorResult.completed
                        case .canceled:
                            return BankTransferClaimCoordinatorResult.canceled
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
