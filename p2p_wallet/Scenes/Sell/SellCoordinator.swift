import Combine
import Foundation
import SwiftUI
import UIKit

typealias SellCoordinatorResult = Void

final class SellCoordinator: Coordinator<SellCoordinatorResult> {

    let navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<SellCoordinatorResult, Never> {
        let viewModel = SellViewModel()
        let vc = UIHostingController(rootView: SellView(viewModel: viewModel))
        navigationController.pushViewController(vc, animated: true)
        return vc.deallocatedPublisher()
    }
}
