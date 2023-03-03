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
    case selectedRoute(SwapSettingsRouteInfo)
}

final class SwapSettingsCoordinator: Coordinator<SwapSettingsCoordinatorResult> {
    
    // MARK: - Public properties

    let statusSubject = CurrentValueSubject<SwapSettingsViewModel.Status, Never>(.loading)
    
    // MARK: - Private properties

    private let navigationController: UINavigationController
    private let slippage: Double
    private var result = PassthroughSubject<SwapSettingsCoordinatorResult, Never>()
    private var viewModel: SwapSettingsViewModel!

    // MARK: - Initializer

    init(
        navigationController: UINavigationController,
        slippage: Double
    ) {
        self.navigationController = navigationController
        self.slippage = slippage
    }

    override func start() -> AnyPublisher<SwapSettingsCoordinatorResult, Never> {
        // create viewModel
        viewModel = SwapSettingsViewModel(
            status: .loading,
            slippage: slippage
        )
        
        // observe statusSubject
        statusSubject
            .assign(to: \.status, on: viewModel)
            .store(in: &subscriptions)
        
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
            .compactMap { status in
                switch status {
                case .loading:
                    return nil
                case .loaded(let info):
                    return info.currentRoute
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
        let view = SwapSelectRouteView(
            statusPublisher: statusSubject
                .map { status in
                    switch status {
                    case .loading:
                        return .loading
                    case .loaded(let info):
                        return .loaded(
                            routeInfos: info.routes,
                            selectedIndex: info.routes
                                .firstIndex(
                                    where: {$0.id == info.currentRoute.id}
                                )
                        )
                    }
                }
                .eraseToAnyPublisher()
        ) { [unowned self] routeInfo in
            switch viewModel.status {
            case .loading:
                break
            case .loaded(let info):
                var info = info
                info.currentRoute = routeInfo
                viewModel.status = .loaded(info)
                navigationController.presentedViewController?.dismiss(animated: true)
            }
        }
        
        let viewController = UIBottomSheetHostingController(rootView: view)
        viewController.view.layer.cornerRadius = 20
        navigationController.present(viewController, interactiveDismissalType: .standard)
        
        statusSubject
            .receive(on: RunLoop.main)
            .sink { [weak viewController] _ in
                viewController?.updatePresentationLayout(animated: false)
            }
            .store(in: &subscriptions)
    }
}
