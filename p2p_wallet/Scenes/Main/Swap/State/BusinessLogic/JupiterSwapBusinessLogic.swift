import Jupiter

enum JupiterSwapBusinessLogic {
    static func jupiterSwapProgressState(
        state: JupiterSwapState,
        action: JupiterSwapAction
    ) -> JupiterSwapState? {
        let newState: JupiterSwapState?
        switch action {
        case .initialize:
            newState = state.copy(status: .initializing)
        case .changeAmountFrom:
            newState = state.copy(status: .loadingAmountTo)
        case .changeFromToken:
            newState = state.copy(status: .loadingAmountTo)
        case .changeToToken:
            newState = state.copy(status: .loadingTokenTo)
        case .changeBothTokens:
            newState = state.copy(status: .switching)
        case .update:
            newState = state.copy(status: .loadingAmountTo)
        }

        return newState
    }

    static func jupiterSwapBusinessLogic(
        state: JupiterSwapState,
        action: JupiterSwapAction,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        let newState: JupiterSwapState
        switch action {
        case let .initialize(swapTokens, routeMap, fromToken):
            newState = await initializeAction(
                state: state,
                services: services,
                swapTokens: swapTokens,
                routeMap: routeMap,
                fromToken: fromToken
            )

        case let .changeAmountFrom(amountFrom):
            newState = await executeAction(state, services, action: {
                await changeAmountFrom(state: state, services: services, amountFrom: amountFrom)
            }, chains: {
                [calculateAmounts]
            })

        case let .changeFromToken(swapToken):
            newState = await executeAction(state, services, action: {
                await changeFromToken(state: state, services: services, token: swapToken)
            }, chains: {
                [calculateAmounts]
            })
        case let .changeToToken(swapToken):
            newState = await executeAction(state, services, action: {
                await changeToToken(state: state, services: services, token: swapToken)
            }, chains: {
                [calculateAmounts]
            })
        case let .changeBothTokens(from, to):
            newState = await executeAction(state, services, action: {
                await changeBothTokens(state: state, services: services, fromToken: from, toToken: to)
            }, chains: {
                [calculateAmounts]
            })

        case .update:
            newState = await calculateAmounts(state: state, services: services)
        }

        return newState
    }
}

private typealias JupiterSwapLogicChainNode = (_ state: JupiterSwapState, _ service: JupiterSwapServices) async -> JupiterSwapState

private func executeAction(
    _: JupiterSwapState,
    _ services: JupiterSwapServices,
    action: () async -> JupiterSwapState,
    chains: () -> [JupiterSwapLogicChainNode]
) async -> JupiterSwapState {
    let state = await action()
    return await executeChain(state, services, chains())
}

private func executeChain(_ state: JupiterSwapState, _ service: JupiterSwapServices, _ chains: [JupiterSwapLogicChainNode]) async -> JupiterSwapState {
    var state = state
    for node in chains {
        state = await node(state, service)
    }
    return state
}
