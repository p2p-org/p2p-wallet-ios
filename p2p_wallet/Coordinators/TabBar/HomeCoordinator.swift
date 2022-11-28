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
import Send

final class HomeCoordinator: Coordinator<Void> {
    @Injected private var analyticsManager: AnalyticsManager

    private let navigationController: UINavigationController
    private weak var tabBarController: TabBarController?

    private var sendCoordinator: SendToken.Coordinator?
    private let scrollSubject = PassthroughSubject<Void, Never>()

    init(navigationController: UINavigationController, tabBarController: TabBarController?) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = HomeViewModel()
        let tokensViewModel = HomeWithTokensViewModel()
        tokensViewModel.earnShow
            .sink(receiveValue: { [unowned self] in
                self.tabBarController?.changeItem(to: .invest)
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
                self.coordinate(
                    to:
                    HomeBuyNotificationCoordinator(
                        tokenFrom: .usdc, tokenTo: token, controller: navigationController
                    )
                )
                .flatMap { result -> AnyPublisher<Void, Never> in
                    switch result {
                    case .showBuy:
                        return self.coordinate(to:
                            BuyCoordinator(
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
            })
            .store(in: &subscriptions)

        tokensViewModel.receiveShow
            .sink(receiveValue: { [unowned self] in
                openReceiveScreen(pubKey: $0)
            })
            .store(in: &subscriptions)
        tokensViewModel.sendShow
            .sink(receiveValue: { [unowned self, weak tokensViewModel] in
                Task {
                    do {
                        let done = await sendToken()
                        if done {
                            tokensViewModel?.scrollToTop()
                        }
                        sendCoordinator = nil
                    }
                }
            })
            .store(in: &subscriptions)
        tokensViewModel.swapShow
            .sink(receiveValue: { [unowned self, weak tokensViewModel] in
                Task {
                    do {
                        let done = await showSwap()
                        if done {
                            tokensViewModel?.scrollToTop()
                        }
                    }
                }
            })
            .store(in: &subscriptions)
        tokensViewModel.walletShow
            .sink(receiveValue: { [unowned self, weak tokensViewModel] pubKey, tokenSymbol in
                Task {
                    do {
                        let done = await walletDetail(pubKey: pubKey, tokenSymbol: tokenSymbol)
                        if done {
                            tokensViewModel?.scrollToTop()
                        }
                    }
                }
            })
            .store(in: &subscriptions)

        return Empty(completeImmediately: false)
            .eraseToAnyPublisher()
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
            }),
            animated: true
        )
    }

    private func openReceiveScreen(pubKey: PublicKey) {
        let coordinator = ReceiveCoordinator(navigationController: navigationController, pubKey: pubKey)
        coordinate(to: coordinator)
        analyticsManager.log(event: AmplitudeEvent.mainScreenReceiveOpen)
        analyticsManager.log(event: AmplitudeEvent.receiveViewed(fromPage: "main_screen"))
    }

    private func sendToken(pubKey _: String? = nil) async -> Bool {
        // Old send
        // let vm = SendToken.ViewModel(
        //     walletPubkey: pubKey,
        //     destinationAddress: nil,
        //     relayMethod: .default
        // )
        // sendCoordinator = SendToken.Coordinator(
        //     viewModel: vm,
        //     navigationController: navigationController
        // )
        // analyticsManager.log(event: AmplitudeEvent.mainScreenSendOpen)
        // analyticsManager.log(event: AmplitudeEvent.sendViewed(lastScreen: "main_screen"))
        //
        // return await withCheckedContinuation { continuation in
        //     sendCoordinator?.doneHandler = { [unowned self] in
        //         navigationController.popToRootViewController(animated: true)
        //         return continuation.resume(with: .success(true))
        //     }
        //     let vc = sendCoordinator?.start(hidesBottomBarWhenPushed: true)
        //     vc?.onClose = {
        //         continuation.resume(with: .success(false))
        //     }
        // }

        // Send send
//        coordinate(to: SendCoordinator(rootViewController: navigationController))
//            .sink {}
//            .store(in: &subscriptions)
        let recipient = Recipient(address: "8JmwhgewSppZ2sDNqGZoKu3bWh8wUKZP8mdbP4M1XQx1", category: .solanaAddress, attributes: Recipient.Attribute.funds)
        coordinate(to: SendInputCoordinator(recipient: recipient, navigationController: navigationController))
            .sink {}
            .store(in: &subscriptions)
        
        return false
    }

    private func showSwap() async -> Bool {
        let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
        let vc = OrcaSwapV2.ViewController(viewModel: vm)
        analyticsManager.log(event: AmplitudeEvent.mainScreenSwapOpen)
        analyticsManager.log(event: AmplitudeEvent.swapViewed(lastScreen: "main_screen"))

        return await withCheckedContinuation { continuation in
            vc.doneHandler = { [unowned self] in
                navigationController.popToRootViewController(animated: true)
                return continuation.resume(with: .success(true))
            }
            vc.onClose = {
                continuation.resume(with: .success(false))
            }
            navigationController.show(vc, sender: nil)
        }
    }

    private func walletDetail(pubKey: String, tokenSymbol: String) async -> Bool {
        let vm = WalletDetail.ViewModel(pubkey: pubKey, symbol: tokenSymbol)
        let vc = WalletDetail.ViewController(viewModel: vm)
        analyticsManager.log(event: AmplitudeEvent.mainScreenTokenDetailsOpen(tokenTicker: tokenSymbol))

        return await withCheckedContinuation { continuation in
            vc.processingTransactionDoneHandler = {
                continuation.resume(with: .success(true))
            }
            vc.onClose = {
                continuation.resume(with: .success(false))
            }
            navigationController.show(vc, sender: nil)
        }
    }

    func scrollToTop() {
        scrollSubject.send()
    }
}
