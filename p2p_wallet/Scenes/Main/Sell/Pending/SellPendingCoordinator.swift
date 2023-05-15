import Combine
import Foundation
import SwiftUI
import UIKit
import Send
import Resolver
import Sell
import KeyAppBusiness

enum SellPendingCoordinatorResult {
    case transactionRemoved
    case cashOutInterupted
    case transactionSent(SendTransaction)
    case cancelled
}

final class SellPendingCoordinator: Coordinator<SellPendingCoordinatorResult> {
    
    // Dependencies
    @Injected private var accountsService: SolanaAccountsService
    
    // MARK: - Properties
    
    private let navigationController: UINavigationController
    private let transaction: SellDataServiceTransaction
    private let fiat: any ProviderFiat
    private var resultSubject = PassthroughSubject<SellPendingCoordinatorResult, Never>()
    private var navigatedFromMoonpay: Bool

    // MARK: - Initializer

    init(transaction: SellDataServiceTransaction, fiat: any ProviderFiat, navigationController: UINavigationController, navigatedFromMoonpay: Bool = false) {
        self.navigationController = navigationController
        self.transaction = transaction
        self.fiat = fiat
        self.navigatedFromMoonpay = navigatedFromMoonpay
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
                receiverAddress: transaction.depositWallet,
                navigatedFromMoonpay: navigatedFromMoonpay
            )
        )
        
        let view = SellPendingView(viewModel: viewModel)
        let viewController = SellPendingHostingController(rootView: view, shouldShowAlert: navigatedFromMoonpay)
        viewController.hidesBottomBarWhenPushed = navigationController.canHideBottomForNextPush
        viewController.backButtonHandler = { [weak self] in
            self?.resultSubject.send(.cashOutInterupted)
        }
        
        navigationController.pushViewController(viewController, animated: false)
        
        // observe viewModel's event
        viewModel.transactionRemoved
            .sink { [weak self] in
                self?.resultSubject.send(.transactionRemoved)
            }
            .store(in: &subscriptions)

        viewModel.send
            .flatMap { [unowned self, navigationController] in
                coordinate(to:
                    SendCoordinator(
                        rootViewController: navigationController,
                        preChosenWallet: accountsService.nativeWallet,
                        preChosenRecipient: Recipient(
                            address: transaction.depositWallet,
                            category: .solanaAddress,
                            attributes: [.funds]
                        ),
                        preChosenAmount: transaction.baseCurrencyAmount,
                        hideTabBar: true,
                        source: .sell,
                        allowSwitchingMainAmountType: false
                    )
                )
            }
            .sink { [weak self] res in
                switch res {
                case .sent(let transaction):
                    self?.resultSubject.send(.transactionSent(transaction))
                default:
                    break
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
