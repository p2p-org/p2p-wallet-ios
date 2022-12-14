import Combine
import Foundation
import SwiftUI
import UIKit

typealias SellPendingCoordinatorResult = Void

final class SellPendingCoordinator: Coordinator<SellPendingCoordinatorResult> {

    let navigationController: UINavigationController
    let transactions: [any ProviderTransaction]
    init(transactions: [any ProviderTransaction], navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.transactions = transactions
    }

    override func start() -> AnyPublisher<SellPendingCoordinatorResult, Never> {
        let vcs = transactions.map { transction in
            let viewModel = SellPendingViewModel(id: transction.id)
            let vc = UIHostingController(rootView: SellPendingView(viewModel: viewModel))
            viewModel.coordinator.dismiss.sink { [weak self] in
                self?.navigationController.popViewController(animated: true)
            }.store(in: &subscriptions)
            
            return vc
        }

        let beneathVCs = navigationController.viewControllers[0..<navigationController.viewControllers.count-1]
        navigationController.viewControllers = beneathVCs + vcs
        return Publishers.MergeMany(vcs.map { $0.deallocatedPublisher() }).prefix(1).eraseToAnyPublisher()
    }
}
