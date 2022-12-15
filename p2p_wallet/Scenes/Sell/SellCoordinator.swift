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

    let viewModel = SellViewModel()
    override func start() -> AnyPublisher<SellCoordinatorResult, Never> {
        // scene navigation
        viewModel.navigationPublisher
            .compactMap {$0}
            .flatMap { [unowned self] in
                navigate(to: $0)
            }
            .sink { _ in }
            .store(in: &subscriptions)

        // create viewController
        let vc = UIHostingController(rootView: SellView(viewModel: viewModel))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
        return vc.deallocatedPublisher()
    }

    // MARK: - Navigation

    private func navigate(to scene: SellNavigation) -> AnyPublisher<Void, Never> {
        switch scene {
        case .webPage(let url):
            return navigateToProviderWebPage(url: url)
                .deallocatedPublisher().handleEvents { _ in } receiveOutput: { [unowned self] _ in
                    self.viewModel.warmUp()
                }.eraseToAnyPublisher()

        case .showPending(let transactions):
            return coordinate(to: SellPendingCoordinator(
                transactions: transactions,
                navigationController: navigationController)
            )
                // .flatMap {navigateToAnotherScene()} // chain another navigation if needed
                // .handleEvents(receiveValue:,receiveCompletion:) // or event make side effect
                .map {_ in ()}
                .eraseToAnyPublisher()
        case .swap:
            return navigateToSwap().deallocatedPublisher().handleEvents { _ in } receiveOutput: { [unowned self] _ in
                self.viewModel.warmUp()
            }.eraseToAnyPublisher()
        }
    }

    private func navigateToProviderWebPage(url: URL) -> UIViewController {
        let vc = SFSafariViewController(url: url)
        vc.modalPresentationStyle = .automatic
        navigationController.present(vc, animated: true)
        return vc
    }

    private func navigateToSwap() -> UIViewController {
        let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
        let vc = OrcaSwapV2.ViewController(viewModel: vm)
        vc.hidesBottomBarWhenPushed = true
        navigationController.present(vc, animated: true)
        return vc
    }
}
