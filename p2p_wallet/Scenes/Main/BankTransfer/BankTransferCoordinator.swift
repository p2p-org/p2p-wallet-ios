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
    @Injected private var metadataService: WalletMetadataService

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
            .flatMap { state in
                let step = self.step(userData: state.value)
                return self.coordinator(
                    for: step,
                    userData: state.value
                )
                .flatMap { result in
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
        var step = BankTransferStep.registration
        if let userId = userData.userId {
            if userData.mobileVerified {
                if userData.kycVerified {
                    step = .transfer
                } else {
                    step = .kyc
                }
            } else {
                step = .otp
            }
        }
        return step
    }

    private func coordinator(for step: BankTransferStep, userData: UserData) -> AnyPublisher<BankTransferFlowResult, Never> {
        switch step {
        case .otp:
            return self.coordinate(
                to: StrigaOTPCoordinator(
                    viewController: viewController,
                    phone: metadataService.metadata?.phoneNumber ?? ""
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
            )
            .map { result in
                switch result {
                case .pass:
                    return BankTransferFlowResult.next
                case .canceled:
                    return BankTransferFlowResult.none
                }
            }
                .eraseToAnyPublisher()
        case .registration:
            return self.coordinate(
                to: BankTransferInfoCoordinator(viewController: viewController)
            ).map { result in
                switch result {
                case .completed:
                    return BankTransferFlowResult.next
                case .canceled:
                    return BankTransferFlowResult.none
                }
            }.eraseToAnyPublisher()
        case .transfer:
            return self.coordinate(to: StrigaTransferCoordinator(
                navigation: viewController
            )).map { BankTransferFlowResult.completed }.eraseToAnyPublisher()
        }
    }

}

enum BankTransferStep: CaseIterable {
    case registration
    case otp
    case kyc
    case transfer
}
