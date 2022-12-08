import Combine
import Foundation
import SwiftUI
import UIKit
import SafariServices

typealias SellCoordinatorResult = Void

final class SellCoordinator: Coordinator<SellCoordinatorResult> {

    let navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<SellCoordinatorResult, Never> {
        // create SellViewModel
        let viewModel = SellViewModel()
        
        // scene navigation
        viewModel.navigationPublisher
            .sink { [unowned self] scene in
                switch scene {
                case .webPage(let url):
                    navigateToProviderWebPage(url: url)
                default:
                    break
                }
            }
            .store(in: &subscriptions)
        
        // create viewController
        let vc = UIHostingController(rootView: SellView(viewModel: viewModel))
        navigationController.pushViewController(vc, animated: true)
        return vc.deallocatedPublisher()
    }
    
    // MARK: - Navigation
    private func navigateToProviderWebPage(url: URL) {
        let vc = SFSafariViewController(url: url)
        vc.modalPresentationStyle = .automatic
        navigationController.present(vc, animated: true)
    }
}
