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
        case .switchFromAndToTokens:
            newState = state.copy(status: .switching)
        case .update:
            newState = state.copy(status: .loadingAmountTo)
        case .updateUserWallets:
            newState = state.copy(status: .switching)
        case .chooseRoute:
            newState = state.copy(status: .loadingAmountTo)
        case .changeSlippageBps:
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
        case let .initialize(swapTokens, routeMap, fromToken, toToken):
            newState = await initializeAction(
                state: state,
                services: services,
                swapTokens: swapTokens,
                routeMap: routeMap,
                fromToken: fromToken,
                toToken: toToken
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
        case .switchFromAndToTokens:
            newState = await executeAction(state, services, action: {
                await switchFromAndToTokens(state: state, services: services)
            }, chains: {
                [calculateAmounts]
            })

        case .update:
            newState = await calculateAmounts(state: state, services: services)
        case let .updateUserWallets(userWallets):
            newState = await executeAction(state, services, action: {
                (try? await updateUserWallets(state: state, userWallets: userWallets)) ?? state
            }, chains: {
                [calculateAmounts]
            })
        case let .changeSlippageBps(slippageBps):
            newState = await executeAction(state, services, action: {
                changeSlippage(state: state, slippageBps: slippageBps)
            }, chains: {
                [calculateAmounts]
            })
        case let .chooseRoute(route):
            let state = state.copy(route: route)
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
