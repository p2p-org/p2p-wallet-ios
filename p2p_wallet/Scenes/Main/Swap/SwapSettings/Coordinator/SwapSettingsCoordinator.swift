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
    private var selectRouteViewController: CustomPresentableViewController!

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
        viewModel.rowTapped
            .sink(receiveValue: { [unowned self] rowIdentifier in
                presentSettingsInfo(rowIdentifier: rowIdentifier)
            })
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
                let slippageBps = Int((self?.viewModel.finalSlippage ?? 0) * 100)
                self?.viewModel.log(slippage: self?.viewModel.finalSlippage ?? 0)
                self?.result.send(.selectedSlippageBps(slippageBps))
                self?.result.send(completion: .finished)
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
                            networkFee: state.networkFee ?? SwapFeeInfo(amount: 0.000005, tokenSymbol: "SOL", tokenName: "Solana", amountInFiat: 0.0001, pct: 0.01, canBePaidByKeyApp: true),
                            accountCreationFee: state.accountCreationFee ?? SwapFeeInfo(amount: 0, tokenSymbol: "SOL", tokenName: "Solana", amountInFiat: 0, pct: 0, canBePaidByKeyApp: false),
                            liquidityFee: state.liquidityFee,
                            minimumReceived: state.minimumReceivedAmount == nil ? nil: .init(
                                amount: state.minimumReceivedAmount!,
                                token: state.toToken.token.symbol
                            ),
                            exchangeRateInfo: state.exchangeRateInfo
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
                .eraseToAnyPublisher(),
            onSelectRoute: { [unowned self] routeInfo in
                switch viewModel.status {
                case .loading:
                    break
                case .loaded(let info):
                    var info = info
                    info.currentRoute = routeInfo
                    viewModel.status = .loaded(info)
                    viewModel.logRoute()
                    selectRouteViewController.dismiss(animated: true) { [weak self] in
                        self?.navigationController.popViewController(animated: true)
                    }
                }
            },
            onTapDone: { [unowned self] in
                navigationController.presentedViewController?.dismiss(animated: true)
            }
        )
        
        selectRouteViewController = UIBottomSheetHostingController(rootView: view)
        selectRouteViewController.view.layer.cornerRadius = 20
        navigationController.present(selectRouteViewController, interactiveDismissalType: .standard)
        
        statusSubject
            .receive(on: RunLoop.main)
            .sink { [weak selectRouteViewController] _ in
                selectRouteViewController?.updatePresentationLayout(animated: false)
            }
            .store(in: &subscriptions)
    }
    
    private func presentSettingsInfo(rowIdentifier: SwapSettingsView.RowIdentifier) {
        // map row identifier to strategy
        let strategy: SwapSettingsInfoViewModel.Strategy
        switch rowIdentifier {
        case .route:
            // for route, there is a special case
            showChooseRoute()
            return
        case .networkFee:
            strategy = .enjoyFreeTransaction
        case .accountCreationFee:
            strategy = .accountCreationFee
        case .liquidityFee:
            guard let info = viewModel.info else { return }
            let fees = info.liquidityFee
                .map { lqFee in
                    SwapSettingsInfoViewModel.Fee(
                        title: L10n.liquidityFee(
                            lqFee.tokenName ?? L10n.unknownToken,
                            "\(lqFee.pct == nil ? L10n.unknown: "\(lqFee.pct!)")%"
                        ),
                        subtitle: lqFee.amount.tokenAmountFormattedString(symbol: lqFee.tokenSymbol ?? "UNKNOWN"),
                        amount: lqFee.amountInFiatDescription
                    )
                }
            strategy = .liquidityFee(fees: fees)
        case .minimumReceived:
            strategy = .minimumReceived
        }
        
        // create viewModel
        let viewModel = SwapSettingsInfoViewModel(strategy: strategy)
        
        // create view
        let view = SwapSettingsInfoView(viewModel: viewModel)
        
        // create hosting controller
        selectRouteViewController = UIBottomSheetHostingController(rootView: view)
        selectRouteViewController.view.layer.cornerRadius = 20
        
        // present bottomSheet
        navigationController.present(selectRouteViewController, interactiveDismissalType: .standard)
    }
}
