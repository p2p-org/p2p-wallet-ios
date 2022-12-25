//
//  HomeCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import Action
import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift
import SwiftUI
import UIKit

enum HomeNavigation: Equatable {
    // HomeWithTokens
    case buy
    case receive(publicKey: PublicKey)
    case send
    case swap
    case cashOut
    case earn
    case wallet(pubKey: String, tokenSymbol: String)
    case actions([WalletActionType])
    // HomeEmpty
    case topUp
    case topUpCoin(Token)
    // Error
    case error(show: Bool)
}

final class HomeCoordinator: Coordinator<Void> {
    
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    private let navigationController: UINavigationController
    private let tabBarController: TabBarController
    private let resultSubject = PassthroughSubject<Void, Never>()
    
    var tokensViewModel: HomeWithTokensViewModel?
    let navigation = PassthroughSubject<HomeNavigation, Never>()

    // MARK: - Initializers

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    // MARK: - Public actions

    func scrollToTop() {
        tokensViewModel?.scrollToTop()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        // Home with tokens
        tokensViewModel = HomeWithTokensViewModel(navigation: navigation)
        
        // home with no token
        let emptyViewModel = HomeEmptyViewModel(navigation: navigation)
        
        // home view
        let viewModel = HomeViewModel()
        let homeView = HomeView(
            viewModel: viewModel,
            viewModelWithTokens: tokensViewModel!,
            emptyViewModel: emptyViewModel
        ).asViewController() as! UIHostingControllerWithoutNavigation<HomeView>
        
        // bind
        Publishers.Merge(
            homeView.viewWillAppear.map { true },
            homeView.viewWillDisappear.map { false }
        )
        .assign(to: \.navigationIsHidden, on: homeView)
        .store(in: &subscriptions)

        // set view controller
        navigationController.setViewControllers([homeView], animated: false)
        navigationController.navigationItem.largeTitleDisplayMode = .never

        navigationController.onClose = { [weak self] in
            self?.resultSubject.send(())
        }
        
        // handle navigation
        navigation
            .flatMap { [unowned self] in
                navigate(to: $0, homeView: homeView)
            }
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    
        // return publisher
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }

    // MARK: - Navigation

    private func navigate(to scene: HomeNavigation, homeView: UIViewController) -> AnyPublisher<Void, Never> {
        switch scene {
        case .buy:
            if available(.buyScenarioEnabled) {
                return coordinate(to: BuyCoordinator(navigationController: navigationController, context: .fromHome))
                    .map {_ in ()}
                    .eraseToAnyPublisher()
            } else {
                return Just(presentBuyView())
                    .eraseToAnyPublisher()
            }
        case .receive(let publicKey):
            let coordinator = ReceiveCoordinator(navigationController: navigationController, pubKey: publicKey)
            analyticsManager.log(event: AmplitudeEvent.mainScreenReceiveOpen)
            analyticsManager.log(event: AmplitudeEvent.receiveViewed(fromPage: "main_screen"))
            return coordinate(to: coordinator)
                .eraseToAnyPublisher()
        case .send:
            return coordinate(
                to: SendCoordinator(
                    rootViewController: navigationController,
                    preChosenWallet: nil,
                    hideTabBar: true
                )
            )
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] result in
                switch result {
                case let .sent(model):
                    self?.navigationController.popToRootViewController(animated: true)
                    self?.showSendTransactionStatus(model: model)
                case .cancelled:
                    break
                }
//                tokensViewModel?.scrollToTop()
            })
            .map {_ in ()}
            .eraseToAnyPublisher()
        case .swap:
            analyticsManager.log(event: AmplitudeEvent.swapViewed(lastScreen: "main_screen"))
            return coordinate(
                to: SwapCoordinator(
                    navigationController: navigationController,
                    initialWallet: nil
                )
            )
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak tokensViewModel] result in
                switch result {
                case .cancel:
                    break
                case .done:
                    tokensViewModel?.scrollToTop()
                }
            })
            .map {_ in ()}
            .eraseToAnyPublisher()
        case .cashOut:
            analyticsManager.log(event: AmplitudeEvent.sellClicked(source: "Main"))
            return coordinate(
                to: SellCoordinator(navigationController: navigationController)
            )
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] result in
                switch result {
                case .completed:
                    self?.tabBarController.changeItem(to: .history)
                case .none:
                    break
                }
            })
            .map {_ in ()}
            .eraseToAnyPublisher()
        case .earn:
            return Just(())
                .eraseToAnyPublisher()
        case .wallet(let pubKey, let tokenSymbol):
            let model = WalletDetailCoordinator.Model(pubKey: pubKey, symbol: tokenSymbol)
            let coordinator = WalletDetailCoordinator(navigationController: navigationController, model: model)
            return coordinate(to: coordinator)
                .receive(on: RunLoop.main)
                .handleEvents(receiveOutput: { [weak tokensViewModel] result in
                    switch result {
                    case .cancel:
                        break
                    case .done:
                        tokensViewModel?.scrollToTop()
                    }
                })
                .map {_ in ()}
                .eraseToAnyPublisher()
        case .actions:
            return Just(())
                .eraseToAnyPublisher()
        case .topUp:
            return Just(!available(.buyScenarioEnabled) ? presentBuyView(): ())
                .eraseToAnyPublisher()
        case .topUpCoin(let token):
            guard [Token.nativeSolana, .usdc].contains(token) else {
                return Just(()).eraseToAnyPublisher()
            }
            let coordinator: Coordinator<Void>
            if available(.buyScenarioEnabled) {
                coordinator = BuyCoordinator(
                    navigationController: navigationController,
                    context: .fromHome,
                    defaultToken: token
                )
            } else {
                coordinator = BuyPreparingCoordinator(
                    navigationController: navigationController,
                    strategy: .show,
                    crypto: token == .usdc ? .usdc : token == .nativeSolana ? .sol : .eth
                )
            }
            return self.coordinate(to: coordinator)
                .eraseToAnyPublisher()
        case .error(let show):
            let walletsRepository = Resolver.resolve(WalletsRepository.self)
            if show {
                homeView.view.showConnectionErrorView(refreshAction: CocoaAction { [unowned homeView] in
                    homeView.view.hideConnectionErrorView()
                    walletsRepository.reload()
                    return .just(())
                })
            }
            return Just(())
                .eraseToAnyPublisher()
        }
    }

    private func presentBuyView() {
        navigationController.present(
            BuyTokenSelection.Scene(onTap: { [unowned self] in
                let coordinator = BuyPreparingCoordinator(
                    navigationController: navigationController,
                    strategy: .show,
                    crypto: $0
                )
                coordinate(to: coordinator)
                    .sink(receiveValue: {})
                    .store(in: &subscriptions)
            }),
            animated: true
        )
    }

    private func showSendTransactionStatus(model: SendTransaction) {
        coordinate(to: SendTransactionStatusCoordinator(parentController: navigationController, transaction: model))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }
}
