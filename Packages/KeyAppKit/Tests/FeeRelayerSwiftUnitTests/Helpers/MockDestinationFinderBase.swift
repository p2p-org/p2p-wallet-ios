import Foundation
import SolanaSwift
@testable import FeeRelayerSwift

class MockDestinationAnalysatorBase: DestinationAnalysator {
    func analyseDestination(
        owner _: PublicKey,
        mint _: PublicKey
    ) async throws -> DestinationAnalysatorResult {
        fatalError()
    }
}
