import Foundation

protocol StrigaClaimTransactionType: RawTransactionType {
    var challengeId: String { get }
}
