import Jupiter
import SolanaSwift
import KeyAppKitCore

enum JupiterSwapAction: Equatable {
    case initialize(
        account: KeyPair?,
        jupiterTokens: [Token],
        routeMap: RouteMap,
        preChosenFromTokenMintAddress: String?,
        preChosenToTokenMintAddress: String?
    )

    case update

    case changeAmountFrom(Double)

    case changeFromToken(SwapToken)
    case changeToToken(SwapToken)
    case switchFromAndToTokens
    
    case updateUserWallets(userWallets: [SolanaAccount])
    case updateTokensPriceMap([String: Double])
    
    case chooseRoute(Route)
    case changeSlippageBps(Int)
    
    // MARK: - Helper

    var description: String {
        switch self {
        case .initialize:
            return "initialize"
        case .update:
            return "update"
        case .changeAmountFrom(let double):
            return "changeAmountFrom(\(double))"
        case .changeFromToken(let swapToken):
            return "changeFromToken(\(swapToken.token.symbol))"
        case .changeToToken(let swapToken):
            return "changeToToken(\(swapToken.token.symbol))"
        case .switchFromAndToTokens:
            return "switchFromAndToTokens"
        case .updateUserWallets:
            return "updateUserWallets"
        case .updateTokensPriceMap:
            return "updateTokensPriceMap"
        case .chooseRoute(let route):
            return "chooseRoute(\(route.id))"
        case .changeSlippageBps(let int):
            return "changeSlippageBps(\(int))"
        }
    }
}
