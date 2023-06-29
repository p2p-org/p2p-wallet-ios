import Foundation

/// Striga Claim trasaction type
protocol StrigaClaimTransactionType: RawTransactionType {
    var challengeId: String { get }
}

/// Default implemetation of `StrigaClaimTransactionType`
struct StrigaClaimTransaction: StrigaClaimTransactionType {

    // MARK: - Properties

    let challengeId: String
    let mainDescription: String

    // MARK: - Methods

    func createRequest() async throws -> String {
        // get transaction from proxy api
        
        // sign transaction
        
        // TODO: - send to blockchain
        ""
    }
}
