import Foundation
import SolanaSwift
@testable import FeeRelayerSwift

class MockDestinationAnalysatorBase: DestinationAnalysator {
    func analyseDestination(
        owner: PublicKey,
        mint: PublicKey
    ) async throws -> DestinationAnalysatorResult {
        fatalError()
    }
}
