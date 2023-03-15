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
    private let swapStatePublisher: AnyPublisher<JupiterSwapState, Never>
    private var selectRouteViewController: CustomPresentableViewController!

    // MARK: - Initializer

    init(
        navigationController: UINavigationController,
        slippage: Double,
        swapStatePublisher: AnyPublisher<JupiterSwapState, Never>
    ) {
        self.navigationController = navigationController
        self.slippage = slippage
        self.swapStatePublisher = swapStatePublisher
        super.init()
    }

    override func start() -> AnyPublisher<SwapSettingsCoordinatorResult, Never> {
        // create viewModel
        viewModel = SwapSettingsViewModel(
            status: .loading,
            slippage: slippage,
            swapStatePublisher: swapStatePublisher
        )
        
        // navigation
        viewModel.rowTapped
            .sink(receiveValue: { [unowned self] rowIdentifier in
                presentSettingsInfo(rowIdentifier: rowIdentifier)
            })
            .store(in: &subscriptions)
        
        viewModel.$status
            .compactMap { status in
                switch status {
                case .loading, .empty:
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
                if let slippage = self?.viewModel.slippage,
                   slippage > 0
                {
                    let slippageBps = Int(slippage * 100)
                    self?.viewModel.log(slippage: slippage)
                    self?.result.send(.selectedSlippageBps(slippageBps))
                }
                
                self?.result.send(completion: .finished)
            })
            .store(in: &subscriptions)
        
        return result.eraseToAnyPublisher()
    }

    func showChooseRoute() {
        let view = SwapSelectRouteView(
            statusPublisher: viewModel.$status
                .map { status in
                    switch status {
                    case .loading, .empty:
                        return .loading
                    case .loaded(let info):
                        return .loaded(
                            routeInfos: info.routes,
                            selectedIndex: info.routes.firstIndex { $0.id == info.currentRoute.id }
                        )
                    }
                }
                .eraseToAnyPublisher(),
            onSelectRoute: { [unowned self] routeInfo in
                switch viewModel.status {
                case .loading, .empty:
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
        
        viewModel.$status
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
            guard let info = viewModel.info else { return }
            let fees = info.liquidityFee.mappedToSwapSettingInfoViewModelFee()
            strategy = .liquidityFee(fees: fees)
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
        // TODO: - Only liquidity fees?
        if rowIdentifier == .liquidityFee {
            viewModel.$status
                .compactMap { $0.info?.liquidityFee.mappedToSwapSettingInfoViewModelFee() }
                .sink { [weak settingsInfoViewModel] fees in
                    settingsInfoViewModel?.fees = fees
                    DispatchQueue.main.async { [weak self] in
                        self?.selectRouteViewController.updatePresentationLayout(animated: true)
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

// MARK: - Helpers

private extension Array where Element == SwapFeeInfo {
    func mappedToSwapSettingInfoViewModelFee() -> [SwapSettingsInfoViewModel.Fee] {
        map { lqFee in
            SwapSettingsInfoViewModel.Fee(
                title: L10n.liquidityFee(
                    lqFee.tokenName ?? L10n.unknownToken,
                    "\(lqFee.pct == nil ? L10n.unknown: "\(NSDecimalNumber(decimal: lqFee.pct!).doubleValue.toString(maximumFractionDigits: 9))")%"
                ),
                subtitle: lqFee.amount.tokenAmountFormattedString(symbol: lqFee.tokenSymbol ?? "UNKNOWN"),
                amount: lqFee.amountInFiatDescription
            )
        }
    }
}
