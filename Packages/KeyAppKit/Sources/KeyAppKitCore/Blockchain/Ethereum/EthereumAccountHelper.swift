import Foundation

public extension Array where Element == EthereumAccount {
    /// Helper method for quickly extraction native account.
    var native: Element? {
        first {
            if case .native = $0.token.contractType {
                return true
            } else {
                return false
            }
        }
    }
}
