import Foundation
import SolanaSwift
import Send

struct ClaimSentViaLinkTransaction: RawTransactionType {
    let claimableTokenInfo: ClaimableTokenInfo
    
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
