import Foundation

public struct StrigaWithdrawalInfo: WithdrawalInfoType, Codable {
    public var IBAN: String?
    public var BIC: String?
    public var receiver: String

    public init(IBAN: String? = nil, BIC: String? = nil, receiver: String) {
        self.IBAN = IBAN
        self.BIC = BIC
        self.receiver = receiver
    }
}
