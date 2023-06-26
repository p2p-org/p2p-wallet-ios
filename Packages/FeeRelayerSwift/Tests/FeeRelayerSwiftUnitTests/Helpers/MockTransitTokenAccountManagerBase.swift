import Foundation
@testable import FeeRelayerSwift
import OrcaSwapSwift

class MockTransitTokenAccountManagerBase: TransitTokenAccountManager {
    func getTransitToken(pools: PoolsPair) throws -> TokenAccount? {
        fatalError()
    }
    func checkIfNeedsCreateTransitTokenAccount(transitToken: TokenAccount?) async throws -> Bool? {
        fatalError()
    }
}
