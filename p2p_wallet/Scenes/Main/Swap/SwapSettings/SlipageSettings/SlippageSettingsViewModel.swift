import Foundation

private extension Double {
    static let minSlippage: Double = 0.01
    static let maximumSlippage: Double = 50
}

@MainActor
final class SlippageSettingsViewModel: BaseViewModel, ObservableObject {

    // MARK: - Constants
    
    let slippages: [Double?] = [
        0.1, 0.5, 1, nil
    ]
    
    // MARK: - Properties

    @Published private(set) var selectedIndex: Int = 0
    @Published var customSlippage: Double?
    @Published var isCustomSlippageSelected = false
    
    // MARK: - Computed properties
    
    var selectedSlippage: Double? {
        // selected slippage
        if let slippage = slippages[selectedIndex] {
            return slippage
        }
        
        // custom slippage valid
        else if isCustomSlippageValid {
            return customSlippage
        }
        
        // otherwise
        else {
            return nil
        }
    }
    
    var isCustomSlippageValid: Bool {
        guard let customSlippage else { return false }
        return customSlippage >= .minSlippage && customSlippage <= .maximumSlippage
    }
    
    // MARK: - Initializer

    init(slippage: Double) {
        super.init()
        
        if let index = slippages.firstIndex(of: slippage) {
            selectedIndex = index
        } else {
            selectedIndex = slippages.count - 1
            self.customSlippage = slippage
        }
    }
    
    // MARK: - Actions

    func selectRow(at index: Int) {
        // assert changes
        guard selectedIndex != index else {
            return
        }
        
        // set new value
        selectedIndex = index
        
        // reset custom Slippage if it is not set
        isCustomSlippageSelected = selectedIndex == slippages.count - 1
    }
}
