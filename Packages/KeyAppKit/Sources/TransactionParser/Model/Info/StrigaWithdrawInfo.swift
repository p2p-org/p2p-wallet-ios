import Foundation
import SolanaSwift

/// A struct that contains all information about striga withdrawing.
public struct StrigaWithdrawInfo: Hashable {
    public let amount: Double?
    public let token: Token?
    public let IBAN: String
    public let BIC: String

    public init(amount: Double?, token: Token?, IBAN: String, BIC: String) {
        self.amount = amount
        self.token = token
        self.IBAN = IBAN
        self.BIC = BIC
    }
}

extension StrigaWithdrawInfo: Info {
    public var symbol: String? {
        token?.symbol
    }
    
    public var mintAddress: String? {
        token?.address
    }
}
