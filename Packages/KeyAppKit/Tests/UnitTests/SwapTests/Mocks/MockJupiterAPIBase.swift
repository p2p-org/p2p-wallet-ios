import Jupiter
import SolanaSwift

class MockJupiterAPIBase: JupiterAPI {
    
    func quote(
        inputMint: String,
        outputMint: String,
        amount: String,
        swapMode: SwapMode?,
        slippageBps: Int?,
        feeBps: Int?,
        onlyDirectRoutes: Bool?,
        userPublicKey: String?,
        enforceSingleTx: Bool?
    ) async throws -> Jupiter.Response<[Route]> {
        fatalError()
    }
    
    func getTokens() async throws -> [SolanaSwift.Token] {
        fatalError()
    }
    
    func routeMap() async throws -> Jupiter.RouteMap {
        fatalError()
    }
    
    func swap(route: Jupiter.Route, userPublicKey: String, wrapUnwrapSol: Bool, feeAccount: String?, asLegacyTransaction: Bool?, computeUnitPriceMicroLamports: Int?, destinationWallet: String?) async throws -> String? {
        fatalError()
    }
}
