import Jupiter

enum JupiterSwapAction: Equatable {
    case initialize(swapTokens: [SwapToken], routeMap: RouteMap)

    case update

    case changeAmountFrom(Double)

    case changeFromToken(SwapToken)
    case changeToToken(SwapToken)
    case changeBothTokens(from: SwapToken, to: SwapToken)
}
