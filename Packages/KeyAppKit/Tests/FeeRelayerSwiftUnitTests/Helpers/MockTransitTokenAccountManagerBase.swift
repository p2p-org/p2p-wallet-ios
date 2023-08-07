import Foundation
import OrcaSwapSwift
@testable import FeeRelayerSwift

class MockTransitTokenAccountManagerBase: TransitTokenAccountManager {
    func getTransitToken(pools _: PoolsPair) throws -> TokenAccount? {
        fatalError()
    }

    func checkIfNeedsCreateTransitTokenAccount(transitToken _: TokenAccount?) async throws -> Bool? {
        fatalError()
    }
}
