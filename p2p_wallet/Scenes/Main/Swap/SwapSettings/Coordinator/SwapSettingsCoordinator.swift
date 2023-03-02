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

enum SwapSettingsCoordinatorResult<Route: SwapSettingsRouteInfo> {
    case selectedSlippage(Int)
    case selectedRoute(Route)
}

final class SwapSettingsCoordinator<Route: SwapSettingsRouteInfo>: Coordinator<SwapSettingsCoordinatorResult<Route>> {
    private let navigationController: UINavigationController
    private let slippage: Double
    private let currentRoute: Route
    private let routes: [Route]
    private let swapTokens: [SwapToken]
    private var result = PassthroughSubject<SwapSettingsCoordinatorResult<Route>, Never>()
    
    private var viewModel: SwapSettingsViewModel<Route>!

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

    override func start() -> AnyPublisher<SwapSettingsCoordinatorResult<Route>, Never> {
        // create viewModel
        viewModel = SwapSettingsViewModel(
            routes: routes,
            currentRoute: currentRoute,
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
            .compactMap { $0 }
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
            selectedRoute: Binding(
                get: { [unowned self] in
                    viewModel.currentRoute
                },
                set: { [unowned self] in
                    viewModel.currentRoute = $0
                }
            )
        )
        
        let viewController = UIBottomSheetHostingController(rootView: view)
        navigationController.present(viewController, interactiveDismissalType: .standard)
    }
}
