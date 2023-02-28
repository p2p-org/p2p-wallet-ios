import Jupiter
import SolanaSwift

enum JupiterSwapAction: Equatable {
    case initialize(swapTokens: [SwapToken], routeMap: RouteMap, fromToken: SwapToken?, toToken: SwapToken?)

    case update

    case changeAmountFrom(Double)

    case changeFromToken(SwapToken)
    case changeToToken(SwapToken)
    case changeBothTokens(from: SwapToken, to: SwapToken)
    case updateUserWallets(userWallets: [Wallet])
}
