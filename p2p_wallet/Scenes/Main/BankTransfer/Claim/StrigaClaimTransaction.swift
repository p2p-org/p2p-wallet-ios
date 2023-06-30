import Foundation
import Resolver
import KeyAppBusiness
import SolanaSwift

/// Striga Claim trasaction type
protocol StrigaClaimTransactionType: RawTransactionType {
    var challengeId: String { get }
    var token: Token? { get }
    var amount: Double? { get }
    var feeAmount: FeeAmount { get }
    var fromAddress: String { get }
    var receivingAddress: String { get }
}

extension StrigaClaimTransactionType {
    var amountInFiat: Double? {
        guard let token else { return nil}
        guard let value = Resolver.resolve(SolanaPriceService.self)
            .getPriceFromCache(token: token, fiat: Defaults.fiat.rawValue)?.value else { return nil }
        return value * amount
    }
}

/// Default implemetation of `StrigaClaimTransactionType`
struct StrigaClaimTransaction: StrigaClaimTransactionType {

    // MARK: - Properties

    let challengeId: String
    let token: Token?
    let amount: Double?
    let feeAmount: FeeAmount
    let fromAddress: String
    let receivingAddress: String
    
    var mainDescription: String {
        ""
    }

    // MARK: - Methods

    func createRequest() async throws -> String {
        // get transaction from proxy api
        
        // sign transaction
        
        // TODO: - send to blockchain
        try? await Task.sleep(seconds: 1)
        return .fakeTransactionSignature(id: UUID().uuidString)
    }
}
