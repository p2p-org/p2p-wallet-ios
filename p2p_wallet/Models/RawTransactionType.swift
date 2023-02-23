import Foundation
import SolanaSwift

protocol RawTransactionType {
    func createRequest() async throws -> String
    var mainDescription: String { get }
    var networkFees: (total: SolanaSwift.Lamports, token: SolanaSwift.Token)? { get }
    var payingFeeWallet: Wallet? { get }
}
