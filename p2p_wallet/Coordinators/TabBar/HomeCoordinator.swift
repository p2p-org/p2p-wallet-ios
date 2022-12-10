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
    private let resultSubject = PassthroughSubject<Void, Never>()
    
    var tokensViewModel: HomeWithTokensViewModel?
    let navigation = PassthroughSubject<HomeNavigation, Never>()

    // MARK: - Initializers

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
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
        homeView.viewWillAppear
            .sink(receiveValue: { [unowned homeView] in
                homeView.navigationIsHidden = true
            })
            .store(in: &subscriptions)
        homeView.viewWillDisappear
            .sink(receiveValue: { [unowned homeView] in
                homeView.navigationIsHidden = false
            })
            .store(in: &subscriptions)

        // set view controller
        navigationController.setViewControllers([homeView], animated: false)
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
                    navigationController: navigationController,
                    pubKey: nil
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
            
        case .swap:
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
}
