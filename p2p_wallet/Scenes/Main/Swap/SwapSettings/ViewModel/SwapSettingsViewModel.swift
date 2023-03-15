//
//  SwapSettingsViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 28.02.2023.
//

import Combine
import Resolver
import AnalyticsManager
import Jupiter

protocol SwapSettingsViewModelIO: AnyObject {
    var rowTapped: AnyPublisher<SwapSettingsView.RowIdentifier, Never> { get }
}

final class SwapSettingsViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    
    // MARK: - Published properties

    @Published var currentState: JupiterSwapState
    
    @Published var selectedRoute: Route?
    @Published var selectedSlippageBps: Int
    

    // MARK: - Properties

    private let stateMachine: JupiterSwapStateMachine
    private let rowTappedSubject = PassthroughSubject<SwapSettingsView.RowIdentifier, Never>()
    
    var info: JupiterSwapStateInfo {
        currentState.info
    }
    
    // MARK: - Initializer
    
    init(stateMachine: JupiterSwapStateMachine) {
        // capture state machine
        self.stateMachine = stateMachine
        // copy current state
        self.currentState = stateMachine.currentState
        // copy selected route
        self.selectedRoute = stateMachine.currentState.route
        // copy selected slippage
        self.selectedSlippageBps = stateMachine.currentState.slippageBps
        
        super.init()
        bind()
    }

    private func bind() {
        stateMachine.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                // map state to current state, replace by current context
                self.currentState = state.modified {
                    $0.route = self.selectedRoute
                    $0.slippageBps = self.selectedSlippageBps
                }
            }
            .store(in: &subscriptions)
    }

    // MARK: - Actions
    
    func rowClicked(identifier: SwapSettingsView.RowIdentifier) {
        rowTappedSubject.send(identifier)
        log(fee: identifier)
    }
}

// MARK: - SwapSettingsViewModelIO

extension SwapSettingsViewModel: SwapSettingsViewModelIO {
    var rowTapped: AnyPublisher<SwapSettingsView.RowIdentifier, Never> {
        rowTappedSubject.eraseToAnyPublisher()
    }
}

// MARK: - Analytics

extension SwapSettingsViewModel {
    func logRoute() {
        guard let currentRoute = info.currentRoute?.name else { return }
        analyticsManager.log(event: .swapSettingsSwappingThroughChoice(variant: currentRoute))
    }

    func log(slippage: Double) {
        let isCustom = slippage > 1
        if isCustom {
            analyticsManager.log(event: .swapSettingsSlippageCustom(slippageLevelPercent: slippage))
        } else {
            analyticsManager.log(event: .swapSettingsSlippage(slippageLevelPercent: slippage))
        }
    }

    private func log(fee: SwapSettingsView.RowIdentifier) {
        switch fee {
        case .route:
            analyticsManager.log(event: .swapSettingsFeeClick(feeName: "Swapping_Through"))
        case .networkFee:
            analyticsManager.log(event: .swapSettingsFeeClick(feeName: "Network_Fee"))
        case .accountCreationFee:
            analyticsManager.log(event: .swapSettingsFeeClick(feeName: "Sol_Account_Creation"))
        case .liquidityFee:
            analyticsManager.log(event: .swapSettingsFeeClick(feeName: "Liquidity_Fee"))
        default:
            break
        }
    }
}
