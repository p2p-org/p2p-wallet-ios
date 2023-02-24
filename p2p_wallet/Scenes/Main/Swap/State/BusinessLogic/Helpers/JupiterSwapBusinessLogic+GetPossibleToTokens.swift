import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func getPossibleToTokens(fromTokenMint: String, routeMap: RouteMap, swapTokens: [SwapToken]) -> [SwapToken] {
        let toAddresses = Set(routeMap.indexesRouteMap[fromTokenMint] ?? [])
        return swapTokens.filter { toAddresses.contains($0.token.address) }
    }
}
