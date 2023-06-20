import Foundation

public struct StrigaTransactionResendOTPResponse: Codable {
    let challengeId: String
    let dateExpires: String
    let attempts: Int
}
