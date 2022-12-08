import Combine
import Foundation
import SwiftUI
import UIKit

enum SellPendingCoordinatorResult {
    case send
    case forget
}

final class SellPendingCoordinator: Coordinator<SellPendingCoordinatorResult> {

    let navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<SellPendingCoordinatorResult, Never> {
        let viewModel = SellPendingViewModel()
        let vc = UIHostingController(rootView: SellPendingView(viewModel: viewModel))
        navigationController.pushViewController(vc, animated: true)
        return Publishers.Merge(
            vc.deallocatedPublisher().map { SellPendingCoordinatorResult.forget }.eraseToAnyPublisher(),
            viewModel.coordinator.dismiss.map { SellPendingCoordinatorResult.forget }.eraseToAnyPublisher()
        ).prefix(1).eraseToAnyPublisher()
    }
}
