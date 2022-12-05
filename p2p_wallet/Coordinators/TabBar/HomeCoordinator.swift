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

final class HomeCoordinator: Coordinator<Void> {
    @Injected private var analyticsManager: AnalyticsManager

    private let navigationController: UINavigationController

    private let scrollSubject = PassthroughSubject<Void, Never>()

    private let earnSubject = PassthroughSubject<Void, Never>()
    var showEarn: AnyPublisher<Void, Never> { earnSubject.eraseToAnyPublisher() }

    private let resultSubject = PassthroughSubject<Void, Never>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = HomeViewModel()
        let tokensViewModel = HomeWithTokensViewModel()
        tokensViewModel.earnShow
            .sink(receiveValue: { [unowned self] in
                earnSubject.send()
            })
            .store(in: &subscriptions)
        let emptyViewModel = HomeEmptyViewModel()
        let emptyVMOutput = emptyViewModel.output.coord
        let homeView = HomeView(
            viewModel: viewModel,
            viewModelWithTokens: tokensViewModel,
            emptyViewModel: emptyViewModel
        ).asViewController() as! UIHostingControllerWithoutNavigation<HomeView>

        navigationController.setViewControllers([homeView], animated: false)
        navigationController.onClose = { [weak self] in
            self?.resultSubject.send(())
        }

        scrollSubject
            .sink(receiveValue: {
                tokensViewModel.scrollToTop()
            })
            .store(in: &subscriptions)

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

        Publishers.Merge(emptyVMOutput.topUpShow, tokensViewModel.buyShow)
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

        emptyVMOutput.topUpCoinShow
            .filter { [Token.renBTC, .eth, .usdt].contains($0) }
            .map { $0 == .renBTC ? Token(.renBTC, customSymbol: "BTC") : $0 }
            .flatMap { [unowned self] token -> AnyPublisher<Void, Never> in
                self.coordinate(to: HomeBuyNotificationCoordinator(
                    tokenFrom: .usdc, tokenTo: token, controller: navigationController
                ))
                .flatMap { result -> AnyPublisher<Void, Never> in
                    switch result {
                    case .showBuy:
                        return self.coordinate(to: BuyCoordinator(
                            navigationController: self.navigationController,
                            context: .fromHome,
                            defaultToken: .usdc
                        ))
                    default:
                        return Just(()).eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
            }
            .sink(receiveValue: { _ in })
            .store(in: &subscriptions)

        Publishers.Merge(tokensViewModel.buyShow, emptyVMOutput.topUpShow)
            .filter { available(.buyScenarioEnabled) }
            .sink(receiveValue: { [unowned self] _ in
                coordinate(to: BuyCoordinator(navigationController: navigationController, context: .fromHome))
                    .sink(receiveValue: {})
                    .store(in: &subscriptions)
            })
            .store(in: &subscriptions)

        tokensViewModel.receiveShow
            .sink(receiveValue: { [unowned self] in
                openReceiveScreen(pubKey: $0)
            })
            .store(in: &subscriptions)

        tokensViewModel.sendShow
            .flatMap { [unowned self] in
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

        tokensViewModel.swapShow
            .flatMap { [unowned self] in
                coordinate(
                    to: SwapCoordinator(
                        navigationController: navigationController,
                        initialWallet: nil
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
    
        tokensViewModel.walletShow
            .flatMap { [unowned self] pubKey, tokenSymbol in
                let model = WalletDetailCoordinator.Model(pubKey: pubKey, symbol: tokenSymbol)
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
        return resultSubject.prefix(1).eraseToAnyPublisher()
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

    private func openReceiveScreen(pubKey: PublicKey) {
        let coordinator = ReceiveCoordinator(navigationController: navigationController, pubKey: pubKey)
        coordinate(to: coordinator)
            .sink(receiveValue: {})
            .store(in: &subscriptions)
        analyticsManager.log(event: AmplitudeEvent.mainScreenReceiveOpen)
        analyticsManager.log(event: AmplitudeEvent.receiveViewed(fromPage: "main_screen"))
    }

    func scrollToTop() {
        scrollSubject.send()
    }
}
