import AnalyticsManager
import Combine
import Foundation
import Jupiter
import Resolver

final class SwapSettingsViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Published properties

    @Published var currentState: JupiterSwapState
    var selectedSlippage: Double? {
        didSet {
            guard let selectedSlippage else { return }
            log(slippage: selectedSlippage)
        }
    }

    // MARK: - Properties

    private let stateMachine: JupiterSwapStateMachine
    private let rowTappedSubject = PassthroughSubject<SwapSettingsView.RowIdentifier, Never>()

    var info: JupiterSwapStateInfo {
        currentState.info
    }

    var isLoading: Bool {
        currentState.isSettingsLoading
    }

    var isLoadingOrRouteNotNil: Bool {
        isLoading || (currentState.route != nil)
    }

    // MARK: - Initializer

    init(stateMachine: JupiterSwapStateMachine) {
        // capture state machine
        self.stateMachine = stateMachine
        // copy current state
        currentState = stateMachine.currentState
        // copy selected slippage
        selectedSlippage = (Double(stateMachine.currentState.slippageBps) / 100)
            .rounded(decimals: 2)

        super.init()
        bind()
    }

    private func bind() {
        stateMachine.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                // map state to current state, replace by current context
                self.currentState = state
            }
            .store(in: &subscriptions)
    }

    // MARK: - Actions

    func rowClicked(identifier: SwapSettingsView.RowIdentifier) {
        rowTappedSubject.send(identifier)
        log(fee: identifier)
    }
}

extension SwapSettingsViewModel {
    var rowTapped: AnyPublisher<SwapSettingsView.RowIdentifier, Never> {
        rowTappedSubject.eraseToAnyPublisher()
    }
}

// MARK: - Analytics

extension SwapSettingsViewModel {
    func log(routeInfo: SwapSettingsRouteInfo) {
        analyticsManager.log(event: .swapSettingsSwappingThroughChoice(variant: routeInfo.name))
    }

    func log(slippage: Double) {
        let slippage = slippage.rounded(decimals: 2)
        let isCustom = ![JupiterSwapSlippage.min, JupiterSwapSlippage.avg, JupiterSwapSlippage.max].contains(slippage)
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
