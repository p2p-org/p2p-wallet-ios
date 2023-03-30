import Foundation
import SolanaSwift

struct ClaimSentViaLinkTransaction: RawTransactionType {
    
    let payingFeeWallet: Wallet? = nil
    let feeAmount: FeeAmount = .zero
    
    var mainDescription: String {
        "Claim-sent-via-link"
    }
    
    let execution: () async throws -> TransactionID
    
    func createRequest() async throws -> String {
        try await execution()
    }
}
