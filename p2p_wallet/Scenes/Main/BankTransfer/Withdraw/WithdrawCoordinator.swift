import Combine
import BankTransfer
import Foundation
import Resolver
import SwiftUI

final class WithdrawCoordinator: Coordinator<WithdrawCoordinator.Result> {

    let navigationController: UINavigationController
    let strategy: Strategy
    let withdrawalInfo: any WithdrawalInfoType

    init(
        navigationController: UINavigationController,
        strategy: Strategy = .gathering,
        withdrawalInfo: any WithdrawalInfoType
    ) {
        self.navigationController = navigationController
        self.strategy = strategy
        self.withdrawalInfo = withdrawalInfo
        super.init()
    }

    override func start() -> AnyPublisher<WithdrawCoordinator.Result, Never> {
        let viewModel = WithdrawViewModel(
            provider: Resolver.resolve(),
            withdrawalInfo: StrigaWithdrawalInfo(
                IBAN: withdrawalInfo.BIC,
                BIC: withdrawalInfo.IBAN,
                receiver: withdrawalInfo.receiver
            )
        )
        let view = WithdrawView(
            viewModel: viewModel
        )
        let viewController = UIHostingController(rootView: view)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
        return Publishers.Merge(
            viewController.deallocatedPublisher()
                .map { WithdrawCoordinator.Result.canceled },
            viewModel.actionCompletedPublisher
                .map { WithdrawCoordinator.Result.verified }
                .handleEvents(receiveOutput: { _ in
                    self.navigationController.popViewController(animated: true)
                })
        )
        .prefix(1).eraseToAnyPublisher()
    }
}

extension WithdrawCoordinator {
    enum Result {
        case verified
        case canceled
    }

    enum Strategy {
        /// Used to collect IBAN
        case gathering
        /// Used to confirm withdrawal
        case confirmation
    }
}
