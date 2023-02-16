import Jupiter

enum JupiterSwapBusinessLogic {
    static func jupiterSwapBusinessLogic(
        state: JupiterSwapState,
        action: JupiterSwapAction,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        let newState: JupiterSwapState
        switch action {
        case let .initialize(swapTokens, routeMap):
            newState = await initializeAction(state: state, services: services, swapTokens: swapTokens, routeMap: routeMap)

        case let .changeAmountFrom(amountFrom):
            newState = await changeAmountFrom(state: state, services: services, amountFrom: amountFrom)

        case let .changeFromToken(swapToken):
            newState = await changeFromToken(state: state, services: services, token: swapToken)
        case let .changeToToken(swapToken):
            newState = await changeToToken(state: state, services: services, token: swapToken)
        case let .changeBothTokens(from, to):
            newState = await changeBothTokens(state: state, services: services, fromToken: from, toToken: to)

        case .update:
            newState = await update(state: state, services: services)
        }

        return newState
    }
}
