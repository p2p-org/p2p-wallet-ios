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
    
    // MARK: - Properties

    @Published var routes: [SwapSettingsRouteInfo]
    @Published var currentRoute: SwapSettingsRouteInfo
    
    @Published var networkFee: SwapSettingsFeeInfo?
    @Published var accountCreationFee: SwapSettingsFeeInfo?
    @Published var liquidityFee: [SwapSettingsFeeInfo] = []
    
    var estimatedFees: String {
        (liquidityFee + [networkFee, accountCreationFee].compactMap {$0})
            .compactMap(\.amountInFiat)
            .reduce(0.0, +)
            .formattedFiat()
    }

    @Published var minimumReceived: SwapSettingsTokenAmountInfo?

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
    
    private let selectRouteSubject = PassthroughSubject<Void, Never>()
    var selectRoutePublisher: AnyPublisher<Void, Never> {
        selectRouteSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer

    init(
        routes: [SwapSettingsRouteInfo],
        currentRoute: SwapSettingsRouteInfo,
        networkFee: SwapSettingsFeeInfo? = nil,
        accountCreationFee: SwapSettingsFeeInfo? = nil,
        liquidityFee: [SwapSettingsFeeInfo] = [],
        minimumReceived: SwapSettingsTokenAmountInfo? = nil,
        selectedIndex: Int = 0,
        slippage: Double,
        failureSlippage: Bool = false,
        slippageWasSetUp: Bool = false
    ) {
        self.routes = routes
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
    
    // MARK: - Methods

    func navigateToSelectRoute() {
        selectRouteSubject.send(())
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
