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
        
        viewModel.$currentRoute
            .compactMap {[weak self] selectedRoute in
                self?.routes.first(where: {$0.id == selectedRoute.id})
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
        let view = SwapSelectRouteView(
            routes: viewModel.routes,
            selectedIndex: viewModel.routes.firstIndex(where: {$0.id == viewModel.currentRoute.id})
        ) { [unowned self] route in
            viewModel.currentRoute = route
            navigationController.presentedViewController?.dismiss(animated: true)
        }
        
        let viewController = UIBottomSheetHostingController(rootView: view)
        viewController.view.layer.cornerRadius = 20
        navigationController.present(viewController, interactiveDismissalType: .standard)
    }
}
