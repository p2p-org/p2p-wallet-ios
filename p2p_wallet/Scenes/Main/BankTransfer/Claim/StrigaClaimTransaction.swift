import Foundation
import Resolver
import KeyAppBusiness
import SolanaSwift
import KeyAppKitCore

/// Striga Claim trasaction type
protocol StrigaClaimTransactionType: RawTransactionType {
    var challengeId: String { get }
    var account: BankTransferRenderableAccount? { get }
    var fromAddress: String { get }
    var receivingAddress: String { get }
}

extension StrigaClaimTransactionType {
    var amountInFiat: Double? {
        // TODO: - Fix price
        1
//        guard let token else { return nil}
//        guard let value = Resolver.resolve(SolanaPriceService.self)
//            .getPriceFromCache(token: token, fiat: Defaults.fiat.rawValue)?.value else { return nil }
//        return value * amount
    }
}

/// Default implemetation of `StrigaClaimTransactionType`
struct StrigaClaimTransaction: StrigaClaimTransactionType {

    // MARK: - Properties

    let challengeId: String
    let account: BankTransferRenderableAccount?
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
