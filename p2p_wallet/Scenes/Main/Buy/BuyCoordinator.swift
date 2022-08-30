import Combine
import Foundation
import Resolver
import SwiftUI

final class BuyCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = BuyViewModel()
        let viewController = UIHostingController(rootView: BuyView(viewModel: viewModel))
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
        
//        viewModel.coordinatorIO.didTapTotal.sin
        
        // TODO: 
        return PassthroughSubject<Void, Never>().eraseToAnyPublisher()
    }
}
