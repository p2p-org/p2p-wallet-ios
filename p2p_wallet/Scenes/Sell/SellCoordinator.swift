import Combine
import Foundation
import SwiftUI
import UIKit
import SafariServices

enum SellCoordinatorResult {
    case completed
    case none
}

final class SellCoordinator: Coordinator<SellCoordinatorResult> {
    private let navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    private let viewModel = SellViewModel()
    private let resultSubject = PassthroughSubject<SellCoordinatorResult, Never>()
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
        return Publishers.Merge(
            vc.deallocatedPublisher().map { SellCoordinatorResult.none },
            resultSubject.eraseToAnyPublisher().prefix(1)
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }

    // MARK: - Navigation

    private func navigate(to scene: SellNavigation) -> AnyPublisher<Void, Never> {
        switch scene {
        case .webPage(let url):
            return navigateToProviderWebPage(url: url)
                .deallocatedPublisher()
                .handleEvents(receiveOutput: { [unowned self] _ in
                    self.viewModel.warmUp()
                }).eraseToAnyPublisher()

        case .showPending(let transactions, let fiat):
            return coordinate(to: SellPendingCoordinator(
                transactions: transactions,
                fiat: fiat,
                navigationController: navigationController)
            )
            .handleEvents(receiveOutput: { val in
                switch val {
                case .completed:
                    self.resultSubject.send(SellCoordinatorResult.completed)
                case .none:
                    self.resultSubject.send(SellCoordinatorResult.none)
                }
                debugPrint(val)
            }, receiveCompletion: { compl in
                debugPrint(compl)
            })
            .map { _ in }
            .eraseToAnyPublisher()

                // .flatMap {navigateToAnotherScene()} // chain another navigation if needed
                // .handleEvents(receiveValue:,receiveCompletion:) // or event make side effect
//                .map {_ in ()}
//                .eraseToAnyPublisher()
        case .swap:
            return navigateToSwap().deallocatedPublisher()
                .handleEvents(receiveOutput: { [unowned self] _ in
                    self.viewModel.warmUp()
                }).eraseToAnyPublisher()
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
