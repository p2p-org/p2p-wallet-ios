import Jupiter
import KeyAppKitCore
import SolanaSwift

enum JupiterSwapAction: Equatable {
    case initialize(
        account: KeyPair?,
        jupiterTokens: [TokenMetadata],
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

    case retry(JupiterSwapState.RetryAction)

    // MARK: - Helper

    var description: String {
        switch self {
        case .initialize:
            return "initialize"
        case .update:
            return "update"
        case let .changeAmountFrom(double):
            return "changeAmountFrom(\(double))"
        case let .changeFromToken(swapToken):
            return "changeFromToken(\(swapToken.token.symbol))"
        case let .changeToToken(swapToken):
            return "changeToToken(\(swapToken.token.symbol))"
        case .switchFromAndToTokens:
            return "switchFromAndToTokens"
        case .updateUserWallets:
            return "updateUserWallets"
        case .updateTokensPriceMap:
            return "updateTokensPriceMap"
        case let .chooseRoute(route):
            return "chooseRoute(\(route.id))"
        case let .changeSlippageBps(int):
            return "changeSlippageBps(\(int))"
        case let .retry(action):
            return "action\(action)"
        }
    }
}
