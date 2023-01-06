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
        
        viewModel.transactionRemoved
            .sink { [weak viewModel] _ in
                viewModel?.warmUp()
            }
            .store(in: &subscriptions)
        
        viewModel.cashOutInterupted
            .sink { [weak self] in
                self?.navigationController.popToRootViewController(animated: true)
                self?.resultSubject.send(.none)
            }
            .store(in: &subscriptions)
        
        let vc = UIHostingController(rootView: SellView(viewModel: viewModel))
        vc.hidesBottomBarWhenPushed = navigationController.canHideBottomForNextPush
        navigationController.pushViewController(vc, animated: true)
        
        // scene navigation
        navigation
            .compactMap { $0 }
            .flatMap { [unowned self, unowned vc] in
                navigate(to: $0, mainSellVC: vc)
            }
            .sink { _ in }
            .store(in: &subscriptions)
        viewModel.back
            .sink(receiveValue: { [unowned self] in
                navigationController.popViewController(animated: true)
                resultSubject.send(.none)
            })
            .store(in: &subscriptions)

        return Publishers.Merge(
            vc.deallocatedPublisher().map { .none },
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
                .handleEvents(receiveCompletion: { [weak self] _ in
                    self?.viewModel.warmUp()
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
                        
                        // mark as pending handly, as server may return status a little bit later
                        Task {
                            await self.sellDataService.markAsPending(id: sellTransaction.id)
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
        case .send(let fromWallet, let toRecipient, let amount, let sellTransaction):
            return coordinate(to:
                SendCoordinator(
                    rootViewController: navigationController,
                    preChosenWallet: fromWallet,
                    preChosenRecipient: toRecipient,
                    preChosenAmount: amount,
                    hideTabBar: true,
                    source: .sell,
                    allowSwitchingMainAmountType: false
                )
            )
            .handleEvents(receiveOutput: { [weak self, unowned mainSellVC] result in
                guard let self = self else { return }
                switch result {
                case .sent(let transaction):
                    // pop 1 viewcontrollers send
                    self.navigationController.popToViewController(mainSellVC, animated: true)
                    
                    // mark as pending handly, as server may return status a little bit later
                    Task {
                        await self.sellDataService.markAsPending(id: sellTransaction.id)
                    }
                    
                    // Show status
                    self.navigateToSendTransactionStatus(model: transaction)
                default:
                    self.navigationController.popToRootViewController(animated: true)
                }
                print("SellNavigation result: \(result)")
            }, receiveCompletion: { compl in
                print("SellNavigation compl: \(compl)")
            })
            .map { _ in }
            .eraseToAnyPublisher()
        case .swap:
            return navigateToSwap()
                .deallocatedPublisher()
                .handleEvents(receiveCompletion: { [unowned self] _ in
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
