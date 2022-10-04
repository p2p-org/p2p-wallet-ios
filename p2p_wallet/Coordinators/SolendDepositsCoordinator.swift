//
//  SolendTokenActionCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 29.09.2022.
//

import Combine
import Resolver
import SwiftUI
import UIKit

final class SolendDepositsCoordinator: Coordinator<Void> {
    private let controller: UINavigationController

    init(controller: UINavigationController) {
        self.controller = controller
    }

    override func start() -> AnyPublisher<Void, Never> {
        let resultSubject = PassthroughSubject<Void, Never>()

        let savePoint = controller.viewControllers.last

        let vm = SolendDepositsViewModel()
        vm.withdraw.sink { [unowned self] asset in
            let viewModel = try! DepositSolendViewModel(strategy: .withdraw, initialAsset: asset)
            viewModel.finish.sink { [unowned self] in
                guard let savePoint = savePoint else {
                    controller.popViewController(animated: true)
                    return
                }
                controller.popToViewController(savePoint, animated: true)

            }.store(in: &subscriptions)

            let view = DepositSolendView(viewModel: viewModel)
            let depositVC = view.asViewController(withoutUIKitNavBar: false)
            controller.pushViewController(
                depositVC,
                animated: true
            )
        }.store(in: &subscriptions)

        vm.deposit.sink { [unowned self] asset in
            let wallets: WalletsRepository = Resolver.resolve()
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
        var defaultToken: Buy.CryptoCurrency?
        var targetSymbol: String?
        switch symbol {
        case "USDC": defaultToken = Buy.CryptoCurrency.usdc
        case "SOL": defaultToken = Buy.CryptoCurrency.sol
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
