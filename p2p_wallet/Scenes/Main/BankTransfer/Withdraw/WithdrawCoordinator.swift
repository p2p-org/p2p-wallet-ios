import Combine
import BankTransfer
import Foundation
import Resolver
import SwiftUI

struct WithdrawConfirmationParameters: Equatable {
    let accountId: String
    let amount: String
}

enum WithdrawStrategy {
    /// Used to collect IBAN
    case gathering
    /// Used to confirm withdrawal
    case confirmation(WithdrawConfirmationParameters)
}

final class WithdrawCoordinator: Coordinator<WithdrawCoordinator.Result> {

    let navigationController: UINavigationController
    let strategy: WithdrawStrategy
    let withdrawalInfo: StrigaWithdrawalInfo

    init(
        navigationController: UINavigationController,
        strategy: WithdrawStrategy = .gathering,
        withdrawalInfo: StrigaWithdrawalInfo
    ) {
        self.navigationController = navigationController
        self.strategy = strategy
        self.withdrawalInfo = withdrawalInfo
        super.init()
    }

    override func start() -> AnyPublisher<WithdrawCoordinator.Result, Never> {
        let viewModel = WithdrawViewModel(withdrawalInfo: withdrawalInfo, strategy: strategy)
        let view = WithdrawView(
            viewModel: viewModel
        )
        let viewController = UIHostingController(rootView: view)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
        return Publishers.Merge3(
            viewController.deallocatedPublisher()
                .map { WithdrawCoordinator.Result.canceled },
            viewModel.gatheringCompletedPublisher
                .map { WithdrawCoordinator.Result.verified(IBAN: $0.IBAN, BIC: $0.BIC) }
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.navigationController.popToRootViewController(animated: false)
                }),
            viewModel.paymentInitiatedPublisher
                .map { WithdrawCoordinator.Result.paymentInitiated(challengeId: $0) }
        )
        .prefix(1).eraseToAnyPublisher()
    }
}

extension WithdrawCoordinator {
    enum Result {
        case paymentInitiated(challengeId: String)
        case verified(IBAN: String, BIC: String)
        case canceled
    }
}
