import Combine
import Foundation
import SwiftUI
import UIKit
import Send
import Resolver

enum SellPendingCoordinatorResult {
    case transactionRemoved
    case cashOutInterupted
    case transactionSent(SendTransaction)
    case cancelled
}

final class SellPendingCoordinator: Coordinator<SellPendingCoordinatorResult> {
    
    // MARK: - Dependencies

    @Injected private var walletsRepository: WalletsRepository
    
    // MARK: - Properties
    
    private let navigationController: UINavigationController
    private let transaction: SellDataServiceTransaction
    private let fiat: Fiat
    private var resultSubject = PassthroughSubject<SellPendingCoordinatorResult, Never>()

    // MARK: - Initializer

    init(transaction: SellDataServiceTransaction, fiat: Fiat, navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.transaction = transaction
        self.fiat = fiat
    }

    // MARK: - Methods
    
    override func start() -> AnyPublisher<SellPendingCoordinatorResult, Never> {
        // create viewModel, viewController and push to navigation stack
        let tokenSymbol = "SOL"
        let viewModel = SellPendingViewModel(
            model: SellPendingViewModel.Model(
                id: transaction.id,
                tokenImage: .solanaIcon,
                tokenSymbol: tokenSymbol,
                tokenAmount: transaction.baseCurrencyAmount,
                fiatAmount: transaction.quoteCurrencyAmount,
                currency: fiat,
                receiverAddress: transaction.depositWallet
            )
        )
        
        let viewController = SellPendingView(viewModel: viewModel).asViewController()
        viewController.hidesBottomBarWhenPushed = navigationController.canHideBottomForNextPush
        viewController.navigationItem.title = "\(L10n.cashOut) \(tokenSymbol)"
        navigationController.pushViewController(viewController, animated: true)
        
        // observe viewModel's event
        viewModel.transactionRemoved
            .sink { [weak self] in
                self?.resultSubject.send(.transactionRemoved)
            }
            .store(in: &subscriptions)

        viewModel.back
            .sink(receiveValue: { [unowned viewController] in
                _ = viewController.showAlert(
                    title: L10n.areYouSure,
                    message: L10n.areYouSureYouWantToInterruptCashOutProcessYourTransactionWonTBeFinished,
                    actions: [
                        UIAlertAction(title: L10n.continueTransaction, style: .default),
                        UIAlertAction(title: L10n.interrupt, style: .destructive) { [unowned self] _ in
                            self.resultSubject.send(.cashOutInterupted)
                        }
                    ]
                )
            })
            .store(in: &subscriptions)

        viewModel.send
            .flatMap { [unowned self, navigationController] in
                coordinate(to:
                    SendCoordinator(
                        rootViewController: navigationController,
                        preChosenWallet: walletsRepository.nativeWallet,
                        preChosenRecipient: Recipient(
                            address: transaction.depositWallet,
                            category: .solanaAddress,
                            attributes: [.funds]
                        ),
                        preChosenAmount: transaction.baseCurrencyAmount,
                        hideTabBar: true,
                        source: .sell
                    )
                )
            }
            .sink { [weak self] res in
                switch res {
                case .sent(let transaction):
                    self?.resultSubject.send(.transactionSent(transaction))
                default:
                    self?.resultSubject.send(.cancelled)
                }
            }
            .store(in: &subscriptions)
        
        // return either vc was dellocated or result subject return a value
        return Publishers.Merge(
            viewController.deallocatedPublisher().map { SellPendingCoordinatorResult.cancelled },
            resultSubject.eraseToAnyPublisher()
        )
            .prefix(1).eraseToAnyPublisher()
    }
}
