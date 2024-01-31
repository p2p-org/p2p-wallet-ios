import Foundation
import SendService

public extension SendServiceLimitRemaining {
    func isAvailable(forAmount amount: UInt64) -> Bool {
        remainingAmount >= amount && remainingTransactions > 0
    }
}
