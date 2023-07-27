import Foundation
@testable import SolanaSwift

extension TokenAccountBalance {
    init(amount: Float64, decimals: UInt8) {
        self.init(uiAmount: amount, amount: "\(Double(amount).toLamport(decimals: decimals))", decimals: decimals, uiAmountString: "\(amount)")
    }
}
