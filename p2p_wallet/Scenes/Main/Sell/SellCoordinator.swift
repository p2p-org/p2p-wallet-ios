import AnalyticsManager
import Combine
import Foundation
import SwiftUI
import UIKit
import SafariServices
import Resolver
import Sell

enum SellCoordinatorResult {
    case completed
    case none
}

final class SellCoordinator: Coordinator<SellCoordinatorResult> {

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var sellDataService: any SellDataService

    // MARK: - Properties

    private var navigation = PassthroughSubject<SellNavigation?, Never>()
    private let navigationController: UINavigationController
    private var viewModel: SellViewModel!
    private let resultSubject = PassthroughSubject<SellCoordinatorResult, Never>()
    // TODO: Pass initial amount in token to view model
    private let initialAmountInToken: Double?
    
    // MARK: - Initializer

    init(initialAmountInToken: Double? = nil, navigationController: UINavigationController) {
        self.initialAmountInToken = initialAmountInToken
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
                            transaction: transaction,
                            fiat: fiat,
                            navigationController: navigationController
                        )
                    )
                    .map {($0, transaction)}
                }
            )
                .handleEvents(receiveOutput: { [weak self, unowned mainSellVC] result, sellTransaction in
                    guard let self = self else { return }
                    switch result {
                    case .transactionRemoved:
                        self.navigationController.popViewController(animated: true)
                    case .cashOutInterupted, .cancelled:
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
                        
                        // mark as completed
                        Task {
                            await self.sellDataService.markAsCompleted(id: sellTransaction.id)
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
        analyticsManager.log(event: AmplitudeEvent.sellMoonpay)
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
