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
            .compactMap {$0}
            .flatMap { [unowned self] in
                navigate(to: $0)
            }
            .sink {_ in }
            .store(in: &subscriptions)

        // create viewController
        let vc = UIHostingController(rootView: SellView(viewModel: viewModel))
        navigationController.pushViewController(vc, animated: true)
        return vc.deallocatedPublisher()
    }

    // MARK: - Navigation
    private func navigate(to scene: SellNavigation) -> AnyPublisher<Void, Never> {
        switch scene {
        case .webPage(let url):
            return Just(navigateToProviderWebPage(url: url))
                .eraseToAnyPublisher()
        case .showPending:
            return coordinate(to: SellPendingCoordinator(navigationController: navigationController))
                // .flatMap {navigateToAnotherScene()} // chain another navigation if needed
                // .handleEvents(receiveValue:,receiveCompletion:) // or event make side effect
                .map {_ in ()}
                .eraseToAnyPublisher()
        }
    }
    
    private func navigateToProviderWebPage(url: URL) {
        let vc = SFSafariViewController(url: url)
        vc.modalPresentationStyle = .automatic
        navigationController.present(vc, animated: true)
        // TODO - Make coordinator
    }
}
