//
//  SolendTokenActionCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 29.09.2022.
//

import Combine
import Resolver
import SolanaSwift
import Solend
import SwiftUI
import UIKit

final class SolendDepositsCoordinator: Coordinator<Void> {
    private let controller: UINavigationController

    init(controller: UINavigationController) {
        self.controller = controller
    }

    override func start() -> AnyPublisher<Void, Never> {
        let resultSubject = PassthroughSubject<Void, Never>()

        let actionService = Resolver.resolve(SolendActionService.self)
        let savePoint = controller.viewControllers.last

        let vm = SolendDepositsViewModel()
        vm.withdraw.filter { _ in
            InvestSolendHelper.readyToStartAction(Resolver.resolve(), actionService.getCurrentAction())
        }.flatMap { [unowned self] asset in
            coordinate(to:
                SolendDepositCoordinator(
                    controller: controller,
                    initialAsset: asset,
                    initialStrategy: .withdraw
                ))
        }.sink { [weak self] status in
            if status == true, let savePoint = savePoint {
                self?.controller.popToViewController(savePoint, animated: true)
            }
        }.store(in: &subscriptions)

        vm.deposit.sink { [unowned self] asset in
            guard InvestSolendHelper.readyToStartAction(
                Resolver.resolve(),
                actionService.getCurrentAction()
            ) == true
            else {
                return
            }

            let wallets: WalletsRepository = Resolver.resolve()

            let tokenAccount: Wallet? = wallets
                .getWallets()
                .first(where: { (wallet: Wallet) -> Bool in asset.mintAddress == wallet.mintAddress })

            if (tokenAccount?.amount ?? 0) > 0 {
                // User has a token
                let coordinator = SolendDepositCoordinator(
                    controller: controller,
                    initialAsset: asset,
                    initialStrategy: .deposit
                )
                coordinate(to: coordinator)
                    .sink { [unowned self] status in
                        if status == true, let savePoint = savePoint, actionService.getCurrentAction() != nil {
                            controller.popToViewController(savePoint, animated: true)
                        }
                    }
                    .store(in: &subscriptions)
            } else {
                // User doesn't have a token
                let hasAnotherToken: Bool = wallets.getWallets().first(where: { ($0.lamports ?? 0) > 0 }) != nil
                let coordinator = SolendTopUpForContinueCoordinator(
                    navigationController: controller,
                    model: .init(
                        asset: asset,
                        strategy: hasAnotherToken ? .withoutOnlyTokenForDeposit : .withoutAnyTokens
                    )
                )
                coordinate(to: coordinator)
                    .sink { [unowned self] result in
                        switch result {
                        case .showTrade:
                            Task { await showTrade() }
                        case let .showBuy(symbol):
                            showBuy(symbol: symbol)
                        default: break
                        }
                    }.store(in: &subscriptions)
            }
        }.store(in: &subscriptions)

        let vc = UIHostingController(rootView: SolendDepositsView(viewModel: vm))
        vc.onClose = {
            resultSubject.send(completion: .finished)
        }

        controller.pushViewController(vc, animated: true)
        return resultSubject.eraseToAnyPublisher()
    }

    private func showBuy(symbol: String) {
        // Preparing params for buy view model
        var defaultToken: Token?
        var targetSymbol: String?
        switch symbol {
        case "USDC": defaultToken = Token.usdc
        case "SOL": defaultToken = Token.nativeSolana
        default: targetSymbol = symbol
        }

        let coordinator = BuyCoordinator(
            navigationController: controller,
            context: .fromInvest,
            defaultToken: defaultToken,
            targetTokenSymbol: targetSymbol
        )

        coordinate(to: coordinator)
            .sink {}
            .store(in: &subscriptions)
    }

    private func showTrade() async -> Bool {
        let vm = OrcaSwapV2.ViewModel(initialWallet: nil)
        let vc = OrcaSwapV2.ViewController(viewModel: vm)

        return await withCheckedContinuation { continuation in
            vc.doneHandler = { [unowned self] in
                controller.popToRootViewController(animated: true)
                return continuation.resume(with: .success(true))
            }
            vc.onClose = {
                continuation.resume(with: .success(false))
            }
            controller.show(vc, sender: nil)
        }
    }
}
