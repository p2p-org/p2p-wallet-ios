import Combine
import Foundation
import SwiftUI
import UIKit
import Send
import Resolver

typealias SellPendingCoordinatorResult = Bool

final class SellPendingCoordinator: Coordinator<SellPendingCoordinatorResult> {
    
    // MARK: - Dependencies

    @Injected private var walletsRepository: WalletsRepository
    
    // MARK: - Properties
    
    let navigationController: UINavigationController
    let transaction: SellDataServiceTransaction
    let fiat: Fiat

    // MARK: - Initializer

    init(transaction: SellDataServiceTransaction, fiat: Fiat, navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.transaction = transaction
        self.fiat = fiat
    }

    // MARK: - Methods

//    private var resultSubject = PassthroughSubject<SellPendingCoordinatorResult, Never>()
    private var sellVC: UIViewController?
    override func start() -> AnyPublisher<SellPendingCoordinatorResult, Never> {
        let tokenSymbol = "SOL"
        let resultSubject = PassthroughSubject<Bool, Never>()
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
        
        let viewController = SellPendingView(viewModel: viewModel).asViewController(withoutUIKitNavBar: false)

        viewModel.dismiss
            .sink { [weak self] in
                resultSubject.send(true)
                self?.navigationController.popViewController(animated: true)
            }
            .store(in: &subscriptions)

        viewModel.back
            .sink(receiveValue: { [unowned self] in
                _ = viewController.showAlert(
                    title: L10n.areYouSure,
                    message: L10n.areYouSureYouWantToInterruptCashOutProcessYourTransactionWonTBeFinished,
                    actions: [
                        UIAlertAction(title: L10n.continueTransaction, style: .default),
                        UIAlertAction(title: L10n.interrupt, style: .destructive) { [unowned self] _ in
                            navigationController.popToRootViewController(animated: true)
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
            .sink { res in
                switch res {
                case .sent:
                    resultSubject.send(true)
                default:
                    resultSubject.send(false)
                }
            }
            .store(in: &subscriptions)

        viewController.hidesBottomBarWhenPushed = true
        viewController.navigationItem.title = "\(L10n.cashOut) \(tokenSymbol)"
        
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }
}
