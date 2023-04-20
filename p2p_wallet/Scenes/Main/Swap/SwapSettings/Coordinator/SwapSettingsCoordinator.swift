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
    private let stateMachine: JupiterSwapStateMachine
    private let navigationController: UINavigationController
    private var result = PassthroughSubject<SwapSettingsCoordinatorResult, Never>()
    private var viewModel: SwapSettingsViewModel!
    private var selectRouteViewController: CustomPresentableViewController!

    // MARK: - Initializer

    init(
        navigationController: UINavigationController,
        stateMachine: JupiterSwapStateMachine
    ) {
        self.navigationController = navigationController
        self.stateMachine = stateMachine
        super.init()
    }

    override func start() -> AnyPublisher<SwapSettingsCoordinatorResult, Never> {
        // create viewModel
        viewModel = SwapSettingsViewModel(stateMachine: stateMachine)
        
        // navigation
        viewModel.rowTapped
            .sink(receiveValue: { [unowned self] rowIdentifier in
                presentSettingsInfo(rowIdentifier: rowIdentifier)
            })
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
                if let slippage = self?.viewModel.selectedSlippage,
                   slippage > 0
                {
                    let slippageBps = Int(slippage * 100)
                    self?.result.send(.selectedSlippageBps(slippageBps))
                }
                
                self?.result.send(completion: .finished)
            })
            .store(in: &subscriptions)
        
        return result.eraseToAnyPublisher()
    }

    func showChooseRoute() {
        let view = SwapSelectRouteView(
            statusPublisher: stateMachine.statePublisher
                .map { state in
                    if state.isSettingsLoading {
                        return .loading
                    } else {
                        return .loaded(
                            routeInfos: state.routes.map { $0.mapToInfo(currentState: state) },
                            selectedIndex: state.routes.firstIndex(where: {$0.id == state.route?.id})
                        )
                    }
                }
                .eraseToAnyPublisher(),
            onSelectRoute: { [unowned self] routeInfo in
                viewModel.log(routeInfo: routeInfo)
                result.send(.selectedRoute(routeInfo))
                selectRouteViewController.dismiss(animated: true) { [weak self] in
                    self?.navigationController.popViewController(animated: true)
                }
            },
            onTapDone: { [unowned self] in
                navigationController.presentedViewController?.dismiss(animated: true)
            }
        )
        
        selectRouteViewController = UIBottomSheetHostingController(rootView: view)
        selectRouteViewController.view.layer.cornerRadius = 20
        navigationController.present(selectRouteViewController, interactiveDismissalType: .standard)
        
        stateMachine.statePublisher
            .receive(on: RunLoop.main)
            .sink { _ in
                DispatchQueue.main.async { [weak self] in
                    self?.selectRouteViewController.updatePresentationLayout(animated: true)
                }
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
            strategy = .liquidityFee
        case .minimumReceived:
            strategy = .minimumReceived
        }
        
        // create viewModel
        let settingsInfoViewModel = SwapSettingsInfoViewModel(strategy: strategy)
        
        // handle closing
        settingsInfoViewModel.close
            .sink { [weak self] _ in
                self?.selectRouteViewController.dismiss(animated: true)
            }
            .store(in: &subscriptions)
        
        // create view
        let view = SwapSettingsInfoView(viewModel: settingsInfoViewModel)
        
        // create hosting controller
        selectRouteViewController = UIBottomSheetHostingController(rootView: view)
        selectRouteViewController.view.layer.cornerRadius = 20
        
        // present bottomSheet
        navigationController.present(selectRouteViewController, interactiveDismissalType: .standard)
        
        // observe viewModel status
        if rowIdentifier == .liquidityFee {
            viewModel.$currentState
                .filter { _ in
                    // TODO: - Only liquidity fees?
                    strategy == .liquidityFee
                }
                .map {
                    $0.mappedToSwapSettingInfoViewModelFee()
                }
                .sink { [weak settingsInfoViewModel] loadableFee in
                    settingsInfoViewModel?.loadableFee = loadableFee
                    DispatchQueue.main.async { [weak self] in
                        self?.selectRouteViewController.updatePresentationLayout(animated: true)
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

// MARK: - Helpers

private extension JupiterSwapState {
    func mappedToSwapSettingInfoViewModelFee() -> SwapSettingsInfoViewModel.LoadableFee {
        guard route != nil else {
            return .loading
        }
        
        return .loaded(
            info.liquidityFee.map { lqFee in
                SwapSettingsInfoViewModel.Fee(
                    title: L10n.liquidityFee(
                        lqFee.tokenName ?? L10n.unknownToken,
                        "\(lqFee.pct == nil ? L10n.unknown: "\(NSDecimalNumber(decimal: lqFee.pct!).doubleValue.toString(maximumFractionDigits: 9))")%"
                    ),
                    subtitle: lqFee.amount.tokenAmountFormattedString(symbol: lqFee.tokenSymbol ?? "UNKNOWN"),
                    amount: lqFee.amountInFiatDescription
                )
            }
        )
    }
}
