import BankTransfer
import Combine
import SolanaSwift
import UIKit

final class WithdrawCalculatorCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = WithdrawCalculatorViewModel()
        let view = WithdrawCalculatorView(viewModel: viewModel)
        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.withdraw
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)

        viewModel.openBankTransfer
            .sink { [weak self] _ in self?.openBankTransfer() }
            .store(in: &subscriptions)

        viewModel.openWithdraw
            .sink { [weak self] model in self?.openWithdraw(model: model) }
            .store(in: &subscriptions)

        return vc.deallocatedPublisher().eraseToAnyPublisher()
    }

    private func openBankTransfer() {
        coordinate(to: BankTransferCoordinator(viewController: navigationController))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func openWithdraw(model: StrigaWithdrawalInfo) {
        coordinate(to: WithdrawCoordinator(navigationController: navigationController, withdrawalInfo: model))
            .sink { result in
                switch result {
                case .verified:
                    self.coordinate(to:
                        BankTransferClaimCoordinator(
                            navigationController: self.navigationController,
                            transaction: StrigaClaimTransaction(
                                challengeId: "1",
                                token: .usdc,
                                amount: 120,
                                feeAmount: FeeAmount(
                                    transaction: 0,
                                    accountBalances: 0
                                ),
                                fromAddress: "4iP2r5437gMF5iavTyBApSaMyYUQbtvQ1yhHm6VpnijH",
                                receivingAddress: "4iP2r5437gMF5iavTyBApSaMyYUQbtvQ1yhHm6VpnijH"
                            )
                        ))
                case .canceled:
                    // TODO:
                    break
                }
            }
            .store(in: &subscriptions)
    }
}
