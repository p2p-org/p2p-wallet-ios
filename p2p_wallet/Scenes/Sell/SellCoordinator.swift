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
    // MARK: - Properties

    private var navigation = PassthroughSubject<SellNavigation?, Never>()
    private let navigationController: UINavigationController
    private var viewModel: SellViewModel!
    private let resultSubject = PassthroughSubject<SellCoordinatorResult, Never>()
    
    // MARK: - Initializer

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Methods
    override func start() -> AnyPublisher<SellCoordinatorResult, Never> {
        // create viewController
        viewModel = SellViewModel(navigation: navigation)
        let vc = UIHostingController(rootView: SellView(viewModel: viewModel))
        vc.hidesBottomBarWhenPushed = navigationController.canHideBottomForNextPush
        navigationController.pushViewController(vc, animated: true)
        
        // scene navigation
        navigation
            .compactMap {$0}
            .flatMap { [unowned self, unowned vc] in
                navigate(to: $0, mainSellVC: vc)
            }
            .sink { _ in }
            .store(in: &subscriptions)

        return Publishers.Merge(
            vc.deallocatedPublisher().map { SellCoordinatorResult.none },
            resultSubject.eraseToAnyPublisher()
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }

    // MARK: - Navigation

    private func navigate(to scene: SellNavigation, mainSellVC: UIViewController) -> AnyPublisher<Void, Never> {
        switch scene {
        case .webPage(let url):
            return navigateToProviderWebPage(url: url)
                .deallocatedPublisher()
                .handleEvents(receiveOutput: { [unowned self] _ in
                    viewModel.warmUp()
                }).eraseToAnyPublisher()

        case .showPending(let transactions, let fiat):
            return Publishers.MergeMany(
                transactions.map { transaction in
                    coordinate(
                        to: SellPendingCoordinator(
                            transaction: transactions[0],
                            fiat: fiat,
                            navigationController: navigationController
                        )
                    )
                }
            )
                .handleEvents(receiveOutput: { [weak self, unowned mainSellVC] result in
                    guard let self = self else { return }
                    switch result {
                    case .transactionRemoved, .cancelled:
                        self.navigationController.popViewController(animated: true)
                    case .cashOutInterupted:
                        self.navigationController.popToRootViewController(animated: true)
                        self.resultSubject.send(.none)
                    case .transactionSent(let transaction):
                        // pop 2 viewcontrollers: send and the last pending one
                        let viewControllers = self.navigationController.viewControllers
                        if viewControllers.count < 3 {
                            self.navigationController.popToViewController(mainSellVC, animated: true)
                        } else {
                            self.navigationController.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                        }
                        
                        // Show status
                        self.navigateToSendTransactionStatus(model: transaction)
                    }
                    print("SellNavigation result: \(result)")
                }, receiveCompletion: { compl in
                    print("SellNavigation compl: \(compl)")
                })
                .map { _ in }
                .eraseToAnyPublisher()

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
        vc.hidesBottomBarWhenPushed = navigationController.canHideBottomForNextPush
        navigationController.present(vc, animated: true)
        return vc
    }
    
    private func navigateToSendTransactionStatus(model: SendTransaction) {
        coordinate(to: SendTransactionStatusCoordinator(parentController: navigationController, transaction: model))
            .sink(receiveValue: { [weak self] in
                self?.resultSubject.send(.completed)
                self?.navigationController.popToRootViewController(animated: true)
            })
            .store(in: &subscriptions)
    }
}
