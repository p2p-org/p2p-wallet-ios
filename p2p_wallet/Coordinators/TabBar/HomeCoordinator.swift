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
        let homeView = HomeView(
            viewModel: viewModel,
            viewModelWithTokens: tokensViewModel,
            emptyViewModel: emptyViewModel
        ).asViewController() as! UIHostingControllerWithoutNavigation<HomeView>

        navigationController.setViewControllers([homeView], animated: false)

        homeView.viewWillAppear
            .sink(receiveValue: { [unowned homeView] in
                homeView.navigationIsHidden = true
            })
            .store(in: &subscriptions)
        homeView.viewDidAppear
            .sink(receiveValue: {})
            .store(in: &subscriptions)
        homeView.viewWillDisappear
            .sink(receiveValue: { [unowned homeView] in
                homeView.navigationIsHidden = false
            })
            .store(in: &subscriptions)
        viewModel.scanQrShow
            .sink(receiveValue: { [unowned self] in
                let coordinator = ScanQrCoordinator(navigationController: navigationController)
                coordinate(to: coordinator)
                    .sink(receiveValue: { [weak self] in
                        guard let code = $0 else { return }
                        self?.qrCodeScannerHandler(code: code, tokensViewModel: tokensViewModel)
                    })
                    .store(in: &subscriptions)
                analyticsManager.log(event: .mainScreenQrOpen)
                analyticsManager.log(event: .scanQrOpen(fromPage: "main_screen"))
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
        tokensViewModel.tradeShow
            .sink(receiveValue: { [unowned self, weak tokensViewModel] in
                Task {
                    do {
                        let done = await showTrade()
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

    private func sendToken(pubKey: String? = nil) async -> Bool {
        let vm = SendToken.ViewModel(
            walletPubkey: pubKey,
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
                return continuation.resume(with: .success(true))
            }
            let vc = sendCoordinator?.start(hidesBottomBarWhenPushed: true)
            vc?.onClose = {
                continuation.resume(with: .success(false))
            }
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
            vc.onClose = {
                continuation.resume(with: .success(false))
            }
            navigationController.show(vc, sender: nil)
        }
    }

    private func walletDetail(pubKey: String, tokenSymbol: String) async -> Bool {
        analyticsManager.log(event: .mainScreenTokenDetailsOpen(tokenTicker: tokenSymbol))
        let vm = WalletDetail.ViewModel(pubkey: pubKey, symbol: tokenSymbol)
        let vc = WalletDetail.ViewController(viewModel: vm)

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

    private func qrCodeScannerHandler(code: String, tokensViewModel: HomeWithTokensViewModel) {
        guard NSRegularExpression.publicKey.matches(code) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                do {
                    let done = await self.sendToken(pubKey: code)
                    if done {
                        tokensViewModel.scrollToTop()
                    }
                    self.sendCoordinator = nil
                }
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension HomeCoordinator: UINavigationControllerDelegate {
    func navigationController(_: UINavigationController, didShow _: UIViewController, animated _: Bool) {}
}
