//
//  SwapSettingsViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 28.02.2023.
//

import Combine
import Resolver
import AnalyticsManager

private extension Double {
    static let minSlippage: Double = 0.01
    static let maximumSlippage: Double = 50
}

final class SwapSettingsViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Output
    
    private let rowTappedSubject = PassthroughSubject<SwapSettingsView.RowIdentifier, Never>()
    var rowTapped: AnyPublisher<SwapSettingsView.RowIdentifier, Never> {
        rowTappedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Nested type

    struct Info: Equatable {
        let routes: [SwapSettingsRouteInfo]
        var currentRoute: SwapSettingsRouteInfo
        let networkFee: SwapFeeInfo
        let accountCreationFee: SwapFeeInfo
        let liquidityFee: [SwapFeeInfo]
        let minimumReceived: SwapTokenAmountInfo?
        
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
    }
    
    
    // MARK: - Properties

    @Published var status: Status

    var info: Info? {
        switch status {
        case .loading:
            return nil
        case .loaded(let info):
            return info
        }
    }

    @Published var selectedIndex: Int = 0 {
        didSet {
            if selectedIndex != slippages.count - 1 {
                slippage = ""
            }
            if slippageWasSetUp {
                customSelected = selectedIndex == slippages.count - 1
            }
        }
    }
    @Published var slippage = "" {
        didSet {
            failureSlippage = !slippage.isEmpty && (formattedSlippage < .minSlippage || formattedSlippage > .maximumSlippage)
        }
    }
    @Published var customSelected: Bool
    @Published var failureSlippage = false
    
    let slippages: [Double?] = [
        0.1,
        0.5,
        1,
        nil
    ]
    
    private var formattedSlippage: Double? {
        var slippageWithoutComma = slippage.replacingOccurrences(of: ",", with: ".")
        if slippageWithoutComma.last == "." {
            slippageWithoutComma.removeLast()
        }
        return Double(slippageWithoutComma)
    }
    
    var finalSlippage: Double? {
        slippages[selectedIndex] ?? formattedSlippage
    }
    
    private var slippageWasSetUp = false

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Init

    init(
        status: Status,
        slippage: Double
    ) {
        self.status = status
        self.customSelected = false
        super.init()
        setUpSlippage(slippage)
    }

    private func setUpSlippage(_ slippage: Double) {
        if let index = slippages.firstIndex(of: slippage) {
            selectedIndex = index
        } else {
            selectedIndex = slippages.count - 1
            let formattedSlippage = (String(format: "%.2f", slippage))
                .replacingOccurrences(of: ",", with: Locale.current.decimalSeparator ?? ".")
                .replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ".")
            self.slippage = formattedSlippage
        }
        slippageWasSetUp = true
    }
    
    func rowClicked(identifier: SwapSettingsView.RowIdentifier) {
        rowTappedSubject.send(identifier)
        log(fee: identifier)
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
