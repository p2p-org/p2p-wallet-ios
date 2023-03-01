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

final class SwapSettingsViewModel: ObservableObject {
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
    
    init(slippage: Double) {
        customSelected = false
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
}
