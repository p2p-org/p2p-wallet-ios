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
    case selectedSlippageBps(Int)
    case selectedRoute(SwapSettingsRouteInfo)
}

final class SwapSettingsCoordinator: Coordinator<SwapSettingsCoordinatorResult> {

    // MARK: - Properties

    private let navigationController: UINavigationController
    private let slippage: Double
    private var result = PassthroughSubject<SwapSettingsCoordinatorResult, Never>()
    private var viewModel: SwapSettingsViewModel!
    private let statusSubject = CurrentValueSubject<SwapSettingsViewModel.Status, Never>(.loading)

    // MARK: - Initializer

    init(
        navigationController: UINavigationController,
        slippage: Double,
        swapStatePublisher: AnyPublisher<JupiterSwapState, Never>
    ) {
        self.navigationController = navigationController
        self.slippage = slippage
        
        super.init()
        bind(swapStatePublisher: swapStatePublisher)
    }

    override func start() -> AnyPublisher<SwapSettingsCoordinatorResult, Never> {
        // create viewModel
        viewModel = SwapSettingsViewModel(
            status: .loading,
            slippage: slippage
        )
        
        // observe swapStatePublisher
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
                let slippageBps = Int(slippage * 100)
                self?.result.send(.selectedSlippageBps(slippageBps))
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

        viewModel.infoClicked
            .sink(receiveValue: { [unowned self] strategy in
                presentSettingsInfo(strategy: strategy)
            })
            .store(in: &subscriptions)
        
        return result.eraseToAnyPublisher()
    }
    
    // MARK: - Helpers
    
    private func bind(swapStatePublisher: AnyPublisher<JupiterSwapState, Never>) {
        swapStatePublisher
            .map { state -> SwapSettingsViewModel.Status in
                // assert route
                guard let route = state.route else {
                    return .loading
                }

                switch state.status {
                case .ready:
                    return .loaded(
                        .init(
                            routes: state.routes.map {.init(
                                id: $0.id,
                                name: $0.name,
                                description: $0.priceDescription(bestOutAmount: state.bestOutAmount, toTokenDecimals: state.toToken.token.decimals, toTokenSymbol: state.toToken.token.symbol) ?? "",
                                tokensChain: $0.chainDescription(tokensList: state.swapTokens.map(\.token))
                            )},
                            currentRoute: .init(
                                id: route.id,
                                name: route.name,
                                description: route.priceDescription(bestOutAmount: state.bestOutAmount, toTokenDecimals: state.toToken.token.decimals, toTokenSymbol: state.toToken.token.symbol) ?? "",
                                tokensChain: route.chainDescription(tokensList: state.swapTokens.map(\.token))
                            ),
                            networkFee: state.networkFee,
                            accountCreationFee: state.accountCreationFee,
                            liquidityFee: state.liquidityFee,
                            minimumReceived: state.minimumReceivedAmount == nil ? nil: .init(
                                amount: state.minimumReceivedAmount!,
                                token: state.toToken.token.symbol
                            )
                        )
                    )
                default:
                    return .loading
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak statusSubject] status in
                statusSubject?.send(status)
            }
            .store(in: &subscriptions)
    }

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
    
    private func presentSettingsInfo(strategy: SwapSettingsInfoViewModel.Strategy) {
//        let viewModel = SwapSettingsInfoViewModel(strategy: strategy)
//        let viewController: UIViewController
//        let view = SwapSettingsInfoView(viewModel: viewModel)
//        
//        switch strategy {
//        case .enjoyFreeTransaction, .accountCreationFee, .minimumReceived:
//            transition.containerHeight = 504
//        case .liquidityFee:
//            transition.containerHeight = 634
//        }
//        viewController = view.asViewController()
//        viewController.view.layer.cornerRadius = 16
//        viewController.transitioningDelegate = transition
//        viewController.modalPresentationStyle = .custom
//        navigationController.present(viewController, animated: true)
//        
//        transition.dimmClicked
//            .sink(receiveValue: { _ in
//                viewController.dismiss(animated: true)
//            })
//            .store(in: &subscriptions)
//        viewModel.close
//            .sink(receiveValue: { _ in
//                viewController.dismiss(animated: true)
//            })
//            .store(in: &subscriptions)
    }
}
