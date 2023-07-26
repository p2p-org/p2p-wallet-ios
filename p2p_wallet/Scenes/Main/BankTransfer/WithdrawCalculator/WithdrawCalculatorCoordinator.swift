import BankTransfer
import Resolver
import Combine
import SolanaSwift
import UIKit

final class WithdrawCalculatorCoordinator: Coordinator<WithdrawCalculatorCoordinator.Result> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<WithdrawCalculatorCoordinator.Result, Never> {
        let viewModel = WithdrawCalculatorViewModel()
        let view = WithdrawCalculatorView(viewModel: viewModel)
        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.withdraw
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)

        viewModel.openBankTransfer
            .sink { [weak self] _ in self?.openBankTransfer() }
            .store(in: &subscriptions)

        return Publishers.Merge(
            viewModel.openWithdraw
                .flatMap { [unowned self] model in openWithdraw(model: model) }
                .compactMap { $0 }
                .map { WithdrawCalculatorCoordinator.Result.transaction($0) }
                .eraseToAnyPublisher(),
            vc.deallocatedPublisher()
                .map { WithdrawCalculatorCoordinator.Result.canceled }
                .eraseToAnyPublisher()
        ).prefix(1).eraseToAnyPublisher()
    }

    private func openBankTransfer() {
        coordinate(to: BankTransferCoordinator(viewController: navigationController))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func openWithdraw(model: StrigaWithdrawalInfo) -> AnyPublisher<PendingTransaction?, Never> {
        coordinate(to: WithdrawCoordinator(
            navigationController: navigationController,
            withdrawalInfo: model)
        )
            .handleEvents(receiveOutput: { [unowned self] result in
                switch result {
                case .verified:
                    navigationController.popViewController(animated: true)
                case .canceled, .paymentInitiated:
                    break
                }
            })
            .map({ result -> PendingTransaction? in
                switch result {
                case .verified:
                    let transaction = StrigaWithdrawTransaction(
                        challengeId: "1",
                        IBAN: model.IBAN ?? "",
                        BIC: model.BIC ?? "",
                        amount: 120,
                        feeAmount: FeeAmount(
                            transaction: 0,
                            accountBalances: 0
                        )
                    )

                    // delegate work to transaction handler
                    let transactionIndex = Resolver.resolve(TransactionHandlerType.self)
                        .sendTransaction(transaction)

                    // return pending transaction
                    let pendingTransaction = PendingTransaction(
                        trxIndex: transactionIndex,
                        sentAt: Date(),
                        rawTransaction: transaction,
                        status: .sending
                    )
                    return pendingTransaction
                case .canceled, .paymentInitiated:
                    return nil
                }
            })
            .eraseToAnyPublisher()
    }
}

extension WithdrawCalculatorCoordinator {
    enum Result {
        case transaction(PendingTransaction)
        case canceled
    }
}
