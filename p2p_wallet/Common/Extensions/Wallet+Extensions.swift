import Foundation
import KeyAppKitCore
import SolanaSwift

extension Array where Element == SolanaAccount {
    var isTotalAmountEmpty: Bool {
        contains(where: { $0.amount > 0 }) == false
    }
}
