import Combine
import Foundation
import SwiftUI
import UIKit
import Send
import Resolver

typealias SellPendingCoordinatorResult = Void

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

    override func start() -> AnyPublisher<SellPendingCoordinatorResult, Never> {
        let tokenSymbol = "SOL"
        let vcs = transactions.map { transction in
            let viewModel = SellPendingViewModel(
                model: SellPendingViewModel.Model(
                    id: transction.id,
                    tokenImage: .solanaIcon,
                    tokenSymbol: tokenSymbol,
                    tokenAmount: transction.baseCurrencyAmount,
                    fiatAmount: transction.quoteCurrencyAmount,
                    currency: fiat,
                    receiverAddress: transction.depositWallet
                )
            )

            viewModel.dismiss
                .sink { [weak self] in
                    self?.navigationController.popViewController(animated: true)
                }
                .store(in: &subscriptions)

            viewModel.send
                .flatMap { [unowned self, navigationController] in
                    self.coordinate(to:
                        SendCoordinator(
                            rootViewController: navigationController,
                            preChosenWallet: walletsRepository.nativeWallet,
                            preChosenRecipient: Recipient(
                                address: transction.depositWallet,
                                category: .solanaAddress,
                                attributes: [.funds]
                            ),
                            hideTabBar: true,
                            source: .sell
                        )
                    )
                }
                .sink { _ in }
                .store(in: &subscriptions)

            let viewController = SellPendingView(viewModel: viewModel).asViewController(withoutUIKitNavBar: false)
            viewController.navigationItem.title = "\(L10n.cashOut) \(tokenSymbol)"
            return viewController
        }

        let beneathVCs = navigationController.viewControllers//[0..<navigationController.viewControllers.count-1]
        navigationController.viewControllers = beneathVCs + vcs
        return Publishers
            .MergeMany(vcs.map { $0.deallocatedPublisher() }).collect()
            .flatMap({ _ in
                Just(()).eraseToAnyPublisher()
            })
            .handleEvents(receiveOutput: { _ in
                debugPrint("here")
            })
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
