//
//  SwapSettingsViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 28.02.2023.
//

import Combine
import Resolver
import AnalyticsManager

final class SwapSettingsViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Output
    
    private let rowTappedSubject = PassthroughSubject<SwapSettingsView.RowIdentifier, Never>()
    var rowTapped: AnyPublisher<SwapSettingsView.RowIdentifier, Never> {
        rowTappedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    
    // MARK: - Properties

    @Published var status: Status
    @Published var slippage: Double?

    var info: Info? {
        status.info
    }
    
    // MARK: - Initializer
    
    init(status: Status, slippage: Double?) {
        self.status = status
        self.slippage = slippage
    }

    // MARK: - Actions
    
    func rowClicked(identifier: SwapSettingsView.RowIdentifier) {
        rowTappedSubject.send(identifier)
        log(fee: identifier)
    }
}

// MARK: - Nested type

extension SwapSettingsViewModel {
    struct Info: Equatable {
        let routes: [SwapSettingsRouteInfo]
        var currentRoute: SwapSettingsRouteInfo
        let networkFee: SwapFeeInfo
        let accountCreationFee: SwapFeeInfo
        let liquidityFee: [SwapFeeInfo]
        let minimumReceived: SwapTokenAmountInfo?
        let exchangeRateInfo: String?
        
        var estimatedFees: String {
            "≈ " + (liquidityFee + [networkFee, accountCreationFee].compactMap {$0})
                .compactMap(\.amountInFiat)
                .reduce(0.0, +)
                .formattedFiat()
        }
    }

    enum Status: Equatable {
        case loading
        case loaded(Info)
        
        var info: Info? {
            switch self {
            case .loading:
                return nil
            case .loaded(let info):
                return info
            }
        }
    }
}

// MARK: - Analytics

extension SwapSettingsViewModel {
    func logRoute() {
        guard let currentRoute = info?.currentRoute.name else { return }
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
