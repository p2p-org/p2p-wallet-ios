import Jupiter
import SolanaSwift

enum JupiterSwapAction: Equatable {
    case initialize(swapTokens: [SwapToken], routeMap: RouteMap, fromToken: SwapToken?, toToken: SwapToken?)

    case update

    case changeAmountFrom(Double)

    case changeFromToken(SwapToken)
    case changeToToken(SwapToken)
    case switchFromAndToTokens
    case updateUserWallets(userWallets: [Wallet])
    
    case chooseRoute(Route)
    case changeSlippage(Int)
}