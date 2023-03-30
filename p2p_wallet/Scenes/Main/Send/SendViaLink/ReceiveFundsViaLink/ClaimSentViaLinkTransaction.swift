import Foundation
import SolanaSwift
import Send
import Resolver

struct ClaimSentViaLinkTransaction: RawTransactionType {
    let claimableTokenInfo: ClaimableTokenInfo
    let token: Token
    let destinationWallet: Wallet
    let tokenAmount: Double
    
    let payingFeeWallet: Wallet? = nil
    let feeAmount: FeeAmount = .zero
    
    var mainDescription: String {
        "Claim-sent-via-link"
    }
    
    var amountInFiat: Double? {
        Resolver.resolve(PricesServiceType.self).currentPrice(mint: token.address)?.value * tokenAmount
    }
    
    let execution: () async throws -> TransactionID
    
    func createRequest() async throws -> String {
        try await execution()
    }
}
