//
//  SwapSettingsViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 28.02.2023.
//

import Combine

private extension Double {
    static let minSlippage: Double = 0.01
    static let maximumSlippage: Double = 50
}

final class SwapSettingsViewModel: BaseViewModel, ObservableObject {
    // MARK: - Nested type

    struct RouteInfo {
        let name: String
        let description: String
        let tokens: String
    }
    
    struct TokenAmountInfo {
        let amount: Double
        let token: String?
        
        var amountDescription: String? {
            amount.tokenAmountFormattedString(symbol: token ?? "")
        }
    }
    
    struct FeeInfo {
        let amount: Double
        let token: String?
        let amountInFiat: Double?
        let canBePaidByKeyApp: Bool
        
        var amountDescription: String? {
            amount == 0 && canBePaidByKeyApp ? L10n.paidByKeyApp: amount.tokenAmountFormattedString(symbol: token ?? "")
        }
        var shouldHighlightAmountDescription: Bool {
            amount == 0 && canBePaidByKeyApp
        }
        
        var amountInFiatDescription: String? {
            amount == 0 ? L10n.free: "≈ " + (amountInFiat?.fiatAmountFormattedString() ?? "")
        }
    }
    
    // MARK: - Properties

    @Published var routeInfos: [RouteInfo] = []
    @Published var currentRoute: RouteInfo?
    
    @Published var networkFee: FeeInfo?
    @Published var accountCreationFee: FeeInfo?
    @Published var liquidityFee: [FeeInfo] = []
    
    var estimatedFees: String {
        (liquidityFee + [networkFee, accountCreationFee].compactMap {$0})
            .compactMap(\.amountInFiat)
            .reduce(0.0, +)
            .formattedFiat()
    }

    @Published var minimumReceived: TokenAmountInfo?

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
    
    // MARK: - Initializer

    init(
        routeInfos: [RouteInfo] = [],
        currentRoute: RouteInfo? = nil,
        networkFee: FeeInfo? = nil,
        accountCreationFee: FeeInfo? = nil,
        liquidityFee: [FeeInfo] = [],
        minimumReceived: TokenAmountInfo? = nil,
        selectedIndex: Int = 0,
        slippage: Double,
        failureSlippage: Bool = false,
        slippageWasSetUp: Bool = false
    ) {
        self.routeInfos = routeInfos
        self.currentRoute = currentRoute
        self.networkFee = networkFee
        self.accountCreationFee = accountCreationFee
        self.liquidityFee = liquidityFee
        self.minimumReceived = minimumReceived
        self.selectedIndex = selectedIndex
        self.customSelected = false
        self.failureSlippage = failureSlippage
        self.slippageWasSetUp = slippageWasSetUp
        
        super.init()
        setUpSlippage(slippage)
    }

    // MARK: - Helpers

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
}
