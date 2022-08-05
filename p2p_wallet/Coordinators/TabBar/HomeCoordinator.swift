//
//  HomeCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

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

    private var sendCoordinator: SendToken.Coordinator?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = HomeViewModel()
        let tokensViewModel = HomeWithTokensViewModel()
        let emptyViewModel = HomeEmptyViewModel(
            pricesService: Resolver.resolve(),
            walletsRepository: Resolver.resolve()
        )
        let emptyVMOutput = emptyViewModel.output.coord

        navigationController.setViewControllers(
            [
                HomeView(
                    viewModel: viewModel,
                    viewModelWithTokens: tokensViewModel,
                    emptyViewModel: emptyViewModel
                ).asViewController(),
            ],
            animated: false
        )

        emptyVMOutput.topUpShow
            .sink(receiveValue: { [unowned self] in
                presentBuyView()
            })
            .store(in: &subscriptions)
        emptyVMOutput.topUpCoinShow
            .sink(receiveValue: { [unowned self] in
                let coordinator = BuyPreparingCoordinator(
                    navigationController: navigationController,
                    crypto: $0
                )
                coordinate(to: coordinator)
            })
            .store(in: &subscriptions)
        emptyVMOutput.receiveRenBtcShow
            .sink(receiveValue: { [unowned self] in
                openReceiveScreen(pubKey: $0)
            })
            .store(in: &subscriptions)

        tokensViewModel.buyShow
            .sink(receiveValue: { [unowned self] in
                presentBuyView()
            })
            .store(in: &subscriptions)
        tokensViewModel.receiveShow
            .sink(receiveValue: { [unowned self] in
                openReceiveScreen(pubKey: $0)
            })
            .store(in: &subscriptions)
        tokensViewModel.sendShow
            .sink(receiveValue: { [unowned self] in
                Task {
                    do {
                        let done = await sendToken()
                        if done {
                            tokensViewModel.scrollToTop()
                        }
                    }
                }
            })
            .store(in: &subscriptions)
        tokensViewModel.tradeShow
            .sink(receiveValue: { [unowned self] in
                Task {
                    do {
                        let done = await showTrade()
                        if done {
                            tokensViewModel.scrollToTop()
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
                    crypto: $0
                )
                coordinate(to: coordinator)
            }),
            animated: true
        )
    }

    private func openReceiveScreen(pubKey: PublicKey) {
        let vm = ReceiveToken.SceneModel(
            solanaPubkey: pubKey,
            solanaTokenWallet: nil
        )
        let vc = ReceiveToken.ViewController(viewModel: vm, isOpeningFromToken: false)
        navigationController.show(vc, sender: true)
        analyticsManager.log(event: .mainScreenReceiveOpen)
        analyticsManager.log(event: .receiveViewed(fromPage: "main_screen"))
    }

    private func sendToken() async -> Bool {
        let vm = SendToken.ViewModel(
            walletPubkey: nil,
            destinationAddress: nil,
            relayMethod: .default
        )
        sendCoordinator = SendToken.Coordinator(
            viewModel: vm,
            navigationController: navigationController
        )
        analyticsManager.log(event: .mainScreenSendOpen)
        analyticsManager.log(event: .sendViewed(lastScreen: "main_screen"))

        return await withCheckedContinuation { continuation in
            sendCoordinator?.doneHandler = { [unowned self] in
                navigationController.popToRootViewController(animated: true)
                sendCoordinator = nil
                return continuation.resume(with: .success(true))
            }
            sendCoordinator?.start(hidesBottomBarWhenPushed: true)
        }
    }

    private func showTrade() async -> Bool {
        let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
        let vc = OrcaSwapV2.ViewController(viewModel: vm)
        analyticsManager.log(event: .mainScreenSwapOpen)
        analyticsManager.log(event: .swapViewed(lastScreen: "main_screen"))

        return await withCheckedContinuation { continuation in
            vc.doneHandler = { [unowned self] in
                navigationController.popToRootViewController(animated: true)
                return continuation.resume(with: .success(true))
            }
            navigationController.show(vc, sender: nil)
        }
    }
}
