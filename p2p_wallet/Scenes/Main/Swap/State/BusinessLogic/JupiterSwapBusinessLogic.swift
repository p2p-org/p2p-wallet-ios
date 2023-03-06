import Jupiter

enum JupiterSwapBusinessLogic {
    static func jupiterSwapProgressState(
        state: JupiterSwapState,
        action: JupiterSwapAction
    ) -> JupiterSwapState? {
        switch action {
        case .initialize:
            return state.modified { $0.status = .initializing }
        case .changeAmountFrom:
            return state.modified { $0.status = .loadingAmountTo }
        case .changeFromToken:
            return state.modified { $0.status = .loadingAmountTo }
        case .changeToToken:
            return state.modified { $0.status = .loadingAmountTo }
        case .switchFromAndToTokens:
            return state.modified { $0.status = .switching }
        case .update:
            return state.modified { $0.status = .loadingAmountTo }
        case .updateUserWallets:
            return state.modified { $0.status = .switching }
        case .updateTokensPriceMap:
            return state // no change
        case .chooseRoute:
            return state.modified { $0.status = .loadingAmountTo }
        case .changeSlippageBps:
            return state.modified { $0.status = .loadingAmountTo }
        }
    }

    static func jupiterSwapBusinessLogic(
        state: JupiterSwapState,
        action: JupiterSwapAction,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        switch action {
        case let .initialize(swapTokens, routeMap, fromToken, toToken):
            return await initializeAction(
                state: state,
                services: services,
                swapTokens: swapTokens,
                routeMap: routeMap,
                fromToken: fromToken,
                toToken: toToken
            )

        case let .changeAmountFrom(amountFrom):
            return await calculateAmounts(
                state: state,
                newFromAmount: amountFrom,
                services: services
            )

        case let .changeFromToken(swapToken):
            let state = state.modified {
                $0.fromToken = swapToken
            }
            return await calculateAmounts(
                state: state,
                services: services
            )
        case let .changeToToken(swapToken):
            let state = state.modified {
                $0.toToken = swapToken
            }
            return await calculateAmounts(
                state: state,
                services: services
            )
        case .switchFromAndToTokens:
            let newFromToken = state.toToken
            let newToToken = state.fromToken
            let state = state.modified {
                $0.fromToken = newFromToken
                $0.toToken = newToToken
            }
            return await calculateAmounts(
                state: state,
                services: services
            )
        case .update:
            return await calculateAmounts(state: state, services: services)
        case let .updateUserWallets(userWallets):
            let state = await updateUserWallets(state: state, userWallets: userWallets)
            return await calculateAmounts(state: state, services: services)
        case let .updateTokensPriceMap(tokensPriceMap):
            let state = state.modified { state in
                state.tokensPriceMap = tokensPriceMap
            }
            return state
        case let .changeSlippageBps(slippageBps):
            let state = state.modified {
                $0.slippageBps = slippageBps
            }
            return await calculateAmounts(state: state, services: services)
        case let .chooseRoute(route):
            let state = state.modified {
                $0.route = route
            }
            return await calculateAmounts(state: state, services: services)
        }
    }
}
