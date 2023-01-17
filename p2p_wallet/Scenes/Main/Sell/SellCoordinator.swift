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
    case interupted
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
    private var isCompleted = false
    private var shouldHideRemoveButtonOnFirstAppearance = false

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
            .compactMap { $0 }
            .flatMap { [unowned self] in
                navigate(to: $0)
            }
            .sink { _ in }
            .store(in: &subscriptions)
    
        viewModel.back
            .sink(receiveValue: { [unowned self] in
                // pop viewcontroller and resultSubject.send(.none)
                navigationController.popViewController(animated: true)
            })
            .store(in: &subscriptions)
        
        vc.deallocatedPublisher()
            .sink { [weak self] _ in
                guard let self else {return}
                if !self.isCompleted {
                    self.resultSubject.send(.none)
                }
            }
            .store(in: &subscriptions)

        return resultSubject
            .prefix(1)
            .eraseToAnyPublisher()
    }

    // MARK: - Navigation

    private func navigate(to scene: SellNavigation) -> AnyPublisher<Void, Never> {
        switch scene {
        case .webPage(let url):
            return navigateToProviderWebPage(url: url)
                .deallocatedPublisher()
                .handleEvents(receiveCompletion: { [weak self] _ in
                    self?.viewModel.warmUp()
                    self?.shouldHideRemoveButtonOnFirstAppearance = true
                    self?.viewModel.shouldNotShowKeyboard = false
                }).eraseToAnyPublisher()

        case .showPending(let transactions, let fiat):
            return Publishers.MergeMany(
                transactions.map { transaction in
                    coordinate(
                        to: SellPendingCoordinator(
                            transaction: transaction,
                            fiat: fiat,
                            navigationController: navigationController,
                            shouldHideRemoveButtonOnFirstAppearance: shouldHideRemoveButtonOnFirstAppearance
                        )
                    )
                    .map {($0, transaction)}
                }
            )
                .handleEvents(receiveOutput: { [weak self] result, sellTransaction in
                    guard let self = self else { return }
                    switch result {
                    case .transactionRemoved:
                        self.navigationController.popViewController(animated: true)
                    case .cancelled:
                        // pop to rootViewController and resultSubject.send(.none)
                        self.navigationController.popToRootViewController(animated: true)
                    case .cashOutInterupted:
                        if self.shouldHideRemoveButtonOnFirstAppearance {
                            self.resultSubject.send(.interupted)
                        } else {
                            self.navigationController.popToRootViewController(animated: true)
                        }
                    case .transactionSent(let transaction):
                        // mark as completed
                        self.isCompleted = true
                        
                        // pop to rootViewController
                        self.navigationController.popToRootViewController(animated: true)
                        
                        // mark as pending handly, as server may return status a little bit later
                        Task {
                            await self.sellDataService.markAsPending(id: sellTransaction.id)
                        }
                        
                        // Show status
                        self.navigateToSendTransactionStatus(model: transaction)
                    }
                    self.shouldHideRemoveButtonOnFirstAppearance = false
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
            .sink(receiveCompletion: { [weak self] _ in
                self?.resultSubject.send(.completed)
            }, receiveValue: {})
            .store(in: &subscriptions)
    }
}
