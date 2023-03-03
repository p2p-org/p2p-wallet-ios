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
    
    // MARK: - Output
    
    private let infoClickedSubject = PassthroughSubject<SwapSettingsInfoViewModel.Strategy, Never>()
    var infoClicked: AnyPublisher<SwapSettingsInfoViewModel.Strategy, Never> {
        infoClickedSubject.eraseToAnyPublisher()
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
    
    private let selectRouteSubject = PassthroughSubject<Void, Never>()
    var selectRoutePublisher: AnyPublisher<Void, Never> {
        selectRouteSubject.eraseToAnyPublisher()
    }
    
    private var slippageWasSetUp = false
    
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
        switch identifier {
        case .networkFee:
            infoClickedSubject.send(.enjoyFreeTransaction)
        case .accountCreationFee:
            infoClickedSubject.send(.accountCreationFee)
        case .liquidityFee:
            guard let info else { return }
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
            infoClickedSubject.send(.liquidityFee(fees: fees))
        case .minimumReceived:
            infoClickedSubject.send(.minimumReceived)
        }
    }
    
    func routeClicked() {
        selectRouteSubject.send()
    }
}
