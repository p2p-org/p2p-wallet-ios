//
//  SwapSettingsCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 01.03.2023.
//

import Combine
import Foundation
import UIKit
import SwiftUI
import Jupiter

enum SwapSettingsCoordinatorResult {
    case selectedSlippage(Int)
    case selectedRoute(Route)
}

final class SwapSettingsCoordinator: Coordinator<SwapSettingsCoordinatorResult> {
    private let navigationController: UINavigationController
    private let slippage: Double
    private let currentRoute: Route
    private let routes: [Route]
    private let swapTokens: [SwapToken]
    private var result = PassthroughSubject<SwapSettingsCoordinatorResult, Never>()
    
    private var viewModel: SwapSettingsViewModel!

    init(
        navigationController: UINavigationController,
        slippage: Double,
        routes: [Route],
        currentRoute: Route,
        swapTokens: [SwapToken]
    ) {
        self.navigationController = navigationController
        self.slippage = slippage
        self.currentRoute = currentRoute
        self.routes = routes
        self.swapTokens = swapTokens
    }

    override func start() -> AnyPublisher<SwapSettingsCoordinatorResult, Never> {
        // create viewModel
        let bestPrice = routes.map(\.outAmount).compactMap(UInt64.init).max()
        let tokenB = swapTokens.map(\.token).first(where: {$0.address == routes.first?.marketInfos.last?.outputMint})
        
        viewModel = SwapSettingsViewModel(
            status: .loaded(.init(
                routes: routes.map {.init(
                    id: $0.id,
                    name: $0.name,
                    description: $0.bestPriceDescription(bestPrice: bestPrice, tokenB: tokenB) ?? "",
                    tokensChain: $0.chainDescription(tokensList: swapTokens.map(\.token))
                )},
                currentRoute: .init(
                    id: currentRoute.id,
                    name: currentRoute.name,
                    description: currentRoute.bestPriceDescription(bestPrice: bestPrice, tokenB: tokenB) ?? "",
                    tokensChain: currentRoute.chainDescription(tokensList: swapTokens.map(\.token))
                ),
                networkFee: .init(amount: 0, token: nil, amountInFiat: nil, canBePaidByKeyApp: true),
                accountCreationFee: .init(amount: 0, token: nil, amountInFiat: nil, canBePaidByKeyApp: true),
                liquidityFee: [],
                minimumReceived: .init(amount: 0, token: nil)
            )),
            slippage: slippage
        )
        
        // navigation
        viewModel.selectRoutePublisher
            .sink { [unowned self] _ in
                showChooseRoute()
            }
            .store(in: &subscriptions)
        
        // observe changes
        viewModel.$slippage
            .compactMap { [weak viewModel] _ -> Double? in
                guard viewModel?.failureSlippage != true else {
                    return nil
                }
                return viewModel?.finalSlippage
            }
            .sink { [weak self] slippage in
                let slippage = Int(slippage * 100)
                self?.result.send(.selectedSlippage(slippage))
            }
            .store(in: &subscriptions)
        
        viewModel.$status
            .compactMap { [weak self] status -> Route? in
                switch status {
                case .loading:
                    return nil
                case .loaded(let info):
                    return self?.routes.first(where: {$0.id == info.currentRoute.id})
                }
            }
            .sink { [weak self] route in
                self?.result.send(.selectedRoute(route))
            }
            .store(in: &subscriptions)
        
        // create view
        let view = SwapSettingsView(viewModel: viewModel)
        
        // return viewModel
        let viewController = view.asViewController(withoutUIKitNavBar: false)
        viewController.title = L10n.swapDetails
        navigationController.pushViewController(viewController, animated: true)
        
        // complete Coordinator
        viewController.deallocatedPublisher()
            .sink(receiveValue: { [weak self] in
                self?.result.send(completion: .finished)
            })
            .store(in: &subscriptions)
        
        return result.eraseToAnyPublisher()
    }
    
    // MARK: - Helpers

    func showChooseRoute() {
        let routes = viewModel.info?.routes ?? []
        let view = SwapSelectRouteView(
            routes: routes,
            selectedIndex: routes.firstIndex(where: {$0.id == viewModel.info?.currentRoute.id})
        ) { [unowned self] route in
            // FIXME: - Later
//            viewModel.currentRoute = route
            navigationController.presentedViewController?.dismiss(animated: true)
        }
        
        let viewController = UIBottomSheetHostingController(rootView: view)
        viewController.view.layer.cornerRadius = 20
        navigationController.present(viewController, interactiveDismissalType: .standard)
    }
}
