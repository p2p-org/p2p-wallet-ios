import Foundation
import SolanaSwift

public enum SwapMode: String {
    case exactIn = "ExactIn"
    case exactOut = "ExactOut"
}

public protocol JupiterAPI {
    func getTokens() async throws -> [TokenMetadata]

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
    ) async throws -> Response<[Route]>

    func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        asLegacyTransaction: Bool?,
        computeUnitPriceMicroLamports: Int?,
        destinationWallet: String?
    ) async throws -> SwapTransaction

    func routeMap() async throws -> RouteMap
}

public extension JupiterAPI {
    func swap(
        route: Route,
        userPublicKey: String,
        wrapUnwrapSol: Bool,
        feeAccount: String?,
        computeUnitPriceMicroLamports: Int?
    ) async throws -> SwapTransaction {
        try await swap(
            route: route,
            userPublicKey: userPublicKey,
            wrapUnwrapSol: wrapUnwrapSol,
            feeAccount: feeAccount,
            asLegacyTransaction: nil,
            computeUnitPriceMicroLamports: computeUnitPriceMicroLamports,
            destinationWallet: nil
        )
    }
}
