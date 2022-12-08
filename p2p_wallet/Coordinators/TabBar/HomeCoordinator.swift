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
    case buy
    case receive(publicKey: PublicKey)
    case send
    case swap
    case earn
    case wallet(pubKey: String, tokenSymbol: String)
    case actions([WalletActionType])
}

final class HomeCoordinator: Coordinator<Void> {
    
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    private let navigationController: UINavigationController
    private let scrollSubject = PassthroughSubject<Void, Never>()
    private let earnSubject = PassthroughSubject<Void, Never>()
    private let resultSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Publishers

    var showEarn: AnyPublisher<Void, Never> { earnSubject.eraseToAnyPublisher() }

    // MARK: - Initializers

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public actions

    func scrollToTop() {
        scrollSubject.send()
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        // Home with tokens
        let tokensViewModel = createHomeWithTokensViewModel()
        
        // home with no token
        let emptyViewModel = createHomeEmptyViewModel()
        
        // home view
        let viewModel = HomeViewModel()
        let homeView = HomeView(
            viewModel: viewModel,
            viewModelWithTokens: tokensViewModel,
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
        
        viewModel.errorShow
            .sink(receiveValue: { show in
                let walletsRepository = Resolver.resolve(WalletsRepository.self)
                if show {
                    homeView.view.showConnectionErrorView(refreshAction: CocoaAction {
                        homeView.view.hideConnectionErrorView()
                        walletsRepository.reload()
                        return .just(())
                    })
                }
            })
            .store(in: &subscriptions)

        // set view controller
        navigationController.setViewControllers([homeView], animated: false)
        navigationController.onClose = { [weak self] in
            self?.resultSubject.send(())
        }
    
        return resultSubject.prefix(1).eraseToAnyPublisher()
    }
    
    // MARK: - Helpers

    private func createHomeWithTokensViewModel() -> HomeWithTokensViewModel {
        let tokensViewModel = HomeWithTokensViewModel()
        
        tokensViewModel.navigationPublisher
            .sink { [unowned self] scene in
                switch scene {
                case .earn:
                    earnSubject.send()
                case .buy:
                    if available(.buyScenarioEnabled) {
                        coordinate(to: BuyCoordinator(navigationController: navigationController, context: .fromHome))
                            .sink(receiveValue: {})
                            .store(in: &subscriptions)
                    } else {
                        presentBuyView()
                    }
                case .receive(let publicKey):
                    openReceiveScreen(pubKey: publicKey)
                default:
                    break
                }
            }
            .store(in: &subscriptions)
        
        tokensViewModel.navigationPublisher
            .filter {$0 == .send || $0 == .swap}
            .flatMap { [unowned self] _ in
                coordinate(
                    to: SendCoordinator(
                        navigationController: navigationController,
                        pubKey: nil
                    )
                )
            }
            .sink(receiveValue: { [weak tokensViewModel] result in
                switch result {
                case .cancel:
                    break
                case .done:
                    tokensViewModel?.scrollToTop()
                }
            })
            .store(in: &subscriptions)
        
        tokensViewModel.navigationPublisher
            .compactMap { scene -> (String, String)? in
                switch scene {
                case .wallet(let pubKey, let tokenSymbol):
                    return (pubKey, tokenSymbol)
                default:
                    return nil
                }
            }
            .flatMap { [unowned self] params -> AnyPublisher<WalletDetailCoordinator.Result, Never> in
                let model = WalletDetailCoordinator.Model(pubKey: params.0, symbol: params.1)
                let coordinator = WalletDetailCoordinator(navigationController: navigationController, model: model)
                return coordinate(to: coordinator)
            }
            .sink(receiveValue: { [weak tokensViewModel] result in
                switch result {
                case .cancel:
                    break
                case .done:
                    tokensViewModel?.scrollToTop()
                }
            })
            .store(in: &subscriptions)
        
        scrollSubject
            .sink(receiveValue: { [unowned tokensViewModel] in
                tokensViewModel.scrollToTop()
            })
            .store(in: &subscriptions)
        
        return tokensViewModel
    }
    
    private func createHomeEmptyViewModel() -> HomeEmptyViewModel {
        let emptyViewModel = HomeEmptyViewModel()
        let emptyVMOutput = emptyViewModel.output.coord
        
        emptyVMOutput.topUpShow
            .filter { !available(.buyScenarioEnabled) }
            .sink(receiveValue: { [unowned self] in
                presentBuyView()
            })
            .store(in: &subscriptions)
        
        emptyVMOutput.receive
            .sink(receiveValue: { [unowned self] in
                let coordinator = ReceiveCoordinator(navigationController: navigationController, pubKey: $0)
                coordinate(to: coordinator)
                    .sink(receiveValue: {})
                    .store(in: &subscriptions)
                analyticsManager.log(event: AmplitudeEvent.mainScreenReceiveOpen)
                analyticsManager.log(event: AmplitudeEvent.receiveViewed(fromPage: "main_screen"))
            })
            .store(in: &subscriptions)

        emptyVMOutput.topUpCoinShow
            .filter { [Token.nativeSolana, .usdc].contains($0) }
            .flatMap { [unowned self] cryto -> AnyPublisher<Void, Never> in
                let coordinator: Coordinator<Void>
                if available(.buyScenarioEnabled) {
                    coordinator = BuyCoordinator(
                        navigationController: navigationController,
                        context: .fromHome,
                        defaultToken: cryto
                    )
                } else {
                    coordinator = BuyPreparingCoordinator(
                        navigationController: navigationController,
                        strategy: .show,
                        crypto: cryto == .usdc ? .usdc : cryto == .nativeSolana ? .sol : .eth
                    )
                }
                return self.coordinate(to: coordinator)
            }.sink {}
            .store(in: &subscriptions)
    
        return emptyViewModel
    }

    // MARK: - Navigation

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

    private func openReceiveScreen(pubKey: PublicKey) {
        let coordinator = ReceiveCoordinator(navigationController: navigationController, pubKey: pubKey)
        coordinate(to: coordinator)
            .sink(receiveValue: {})
            .store(in: &subscriptions)
        analyticsManager.log(event: AmplitudeEvent.mainScreenReceiveOpen)
        analyticsManager.log(event: AmplitudeEvent.receiveViewed(fromPage: "main_screen"))
    }
}
