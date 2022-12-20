import Combine
import Foundation
import SwiftUI
import UIKit
import Send
import Resolver

enum SellPendingCoordinatorResult {
    case completed
    case none
}

final class SellPendingCoordinator: Coordinator<SellPendingCoordinatorResult> {
    
    // MARK: - Dependencies

    @Injected private var walletsRepository: WalletsRepository
    
    // MARK: - Properties
    
    let navigationController: UINavigationController
    let transactions: [SellDataServiceTransaction]
    let fiat: Fiat

    // MARK: - Initializer

    init(transactions: [SellDataServiceTransaction], fiat: Fiat, navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.transactions = transactions
        self.fiat = fiat
    }

    // MARK: - Methods

//    private var resultSubject = PassthroughSubject<SellPendingCoordinatorResult, Never>()
    private var sellVC: UIViewController?
    override func start() -> AnyPublisher<SellPendingCoordinatorResult, Never> {
        var resultSubject = PassthroughSubject<SellPendingCoordinatorResult, Never>()
        let tokenSymbol = "SOL"
        let vcs = transactions.map { transaction in
            let vcSubject = PassthroughSubject<Bool, Never>()
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

            viewModel.dismiss
                .sink { [weak self] in
                    vcSubject.send(true)
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
                    self.coordinate(to:
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
                        vcSubject.send(true)
                    default:
                        vcSubject.send(false)
                    }
                }
                .store(in: &subscriptions)

            let viewController = SellPendingView(viewModel: viewModel).asViewController(withoutUIKitNavBar: false)
            viewController.hidesBottomBarWhenPushed = true
            viewController.navigationItem.title = "\(L10n.cashOut) \(tokenSymbol)"
            return (
                viewController,
                vcSubject.eraseToAnyPublisher().prefix(1)
            )
        }

        self.sellVC = navigationController.viewControllers.last
        let beneathVCs = navigationController.viewControllers[0..<navigationController.viewControllers.count-1]
        navigationController.viewControllers = beneathVCs + vcs.map { $0.0 }

        Publishers.MergeMany(vcs.map { $0.1 })
            .collect()
            .handleEvents(receiveOutput: { [unowned self] res in
                resultSubject.send(.completed)
            })
            .sink { [unowned self] res in
                guard let vc = sellVC else { return }
                var viewControllers = navigationController.viewControllers
                viewControllers.insert(vc, at: navigationController.viewControllers.count - 1)
                navigationController.viewControllers = viewControllers
            }.store(in: &subscriptions)

        Publishers.MergeMany(vcs.map { $0.0 }.map { $0.deallocatedPublisher().map { () } }).collect()
            .sink { [weak self] res in
                resultSubject.send(.none)
            }.store(in: &subscriptions)

        return resultSubject.prefix(1).eraseToAnyPublisher()
//            Publishers
//                .MergeMany(
//                    vcs.map { $0.0.deallocatedPublisher() }
//                ).collect()
//                .flatMap { _ in Just(SellPendingCoordinatorResult.none).eraseToAnyPublisher() }
//                .prefix(1)
//                .eraseToAnyPublisher()
    }
}
