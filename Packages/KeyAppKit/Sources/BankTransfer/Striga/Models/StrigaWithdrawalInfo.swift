import Foundation

public struct StrigaWithdrawalInfo: Codable, Equatable {
    public let IBAN: String?
    public let BIC: String?
    public let receiver: String

    public init(IBAN: String? = nil, BIC: String? = nil, receiver: String) {
        self.IBAN = IBAN
        self.BIC = BIC
        self.receiver = receiver
    }
}
