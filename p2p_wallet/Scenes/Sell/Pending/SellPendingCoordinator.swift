import Combine
import Foundation
import SwiftUI
import UIKit

typealias SellPendingCoordinatorResult = Void

final class SellPendingCoordinator: Coordinator<SellPendingCoordinatorResult> {
    let navigationController: UINavigationController
    let transactions: [SellDataServiceTransaction]
    let fiat: Fiat
    init(transactions: [SellDataServiceTransaction], fiat: Fiat, navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.transactions = transactions
        self.fiat = fiat
    }

    override func start() -> AnyPublisher<SellPendingCoordinatorResult, Never> {
        let vcs = transactions.map { transction in
            let viewModel = SellPendingViewModel(transaction: transction, fiat: fiat)
            viewModel.coordinator.dismiss.sink { [navigationController] in
                navigationController.popViewController(animated: true)
            }.store(in: &subscriptions)
            return UIHostingController(rootView: SellPendingView(viewModel: viewModel))
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

    deinit {
        debugPrint("deinit")
    }
}
