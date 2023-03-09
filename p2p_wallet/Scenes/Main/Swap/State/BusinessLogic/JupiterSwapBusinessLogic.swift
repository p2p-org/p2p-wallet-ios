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
            return nil
        case .chooseRoute:
            return nil
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
        case let .initialize(account, swapTokens, routeMap, fromToken, toToken):
            return await initializeAction(
                state: state,
                services: services,
                account: account,
                swapTokens: swapTokens,
                routeMap: routeMap,
                fromToken: fromToken,
                toToken: toToken
            )

        case let .changeAmountFrom(amountFrom):
            let state = await calculateRoute(
                state: state,
                newFromAmount: amountFrom,
                services: services
            )
            
            return await createTransaction(state: state, services: services)

        case let .changeFromToken(swapToken):
            let state = state.modified {
                $0.fromToken = swapToken
            }
            return await calculateRoute(
                state: state,
                newFromAmount: 0, // Reset fromAmount if from token is changed
                services: services
            )
        case let .changeToToken(swapToken):
            var state = state.modified {
                $0.toToken = swapToken
            }
            state = await calculateRoute(
                state: state,
                services: services
            )
            return await createTransaction(state: state, services: services)
        case .switchFromAndToTokens:
            let newFromToken = state.toToken
            let newToToken = state.fromToken
            let newFromAmount = state.amountTo
            var state = state.modified {
                $0.fromToken = newFromToken
                $0.toToken = newToToken
            }
            state = await calculateRoute(
                state: state,
                newFromAmount: newFromAmount,
                services: services
            )
            return await createTransaction(state: state, services: services)
        case .update:
            let state = await calculateRoute(state: state, services: services)
            return await createTransaction(state: state, services: services)
        case let .updateUserWallets(userWallets):
            return await updateUserWallets(state: state, userWallets: userWallets, services: services)
        case let .updateTokensPriceMap(tokensPriceMap):
            return state.modified {
                $0.tokensPriceMap = tokensPriceMap
            }
        case let .changeSlippageBps(slippageBps):
            // return current state if slippage isn't changed
            guard slippageBps != state.slippageBps else {
                return state
                    .modified {
                        $0.status = .ready
                    }
            }
            
            // modify slippage
            var state = state.modified {
                $0.status = .ready
                $0.slippageBps = slippageBps
            }
            
            // re-calculate the route
            state = await calculateRoute(state: state, services: services)
            
            // create swap transaction
            return await createTransaction(state: state, services: services)
        case let .chooseRoute(route):
            // return current route if it is not changed
            guard route != state.route else { return state }
            
            // modify the route
            let state = state.modified {
                $0.route = route
            }
            
            // create swap transaction
            return await createTransaction(state: state, services: services)

        }
    }
}
