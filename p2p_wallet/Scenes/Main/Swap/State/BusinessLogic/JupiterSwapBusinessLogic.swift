import Jupiter

enum JupiterSwapBusinessLogic {
    static func shouldPerformAction(
        state: JupiterSwapState,
        action: JupiterSwapAction
    ) -> Bool {
        // perform action whenever error appears
        if state.status.hasError {
            return true
        }
        
        // otherwise check the action
        switch action {
        case .initialize:
            return true
        case .update:
            return true
        case .changeAmountFrom(let amountFrom):
            return state.amountFrom != amountFrom
        case .changeFromToken(let fromToken):
            return state.fromToken.address != fromToken.address
        case .changeToToken(let toToken):
            return state.toToken.address != toToken.address
        case .switchFromAndToTokens:
            return true
        case .updateUserWallets:
            return true
        case .updateTokensPriceMap(let tokensPriceMap):
            return state.tokensPriceMap != tokensPriceMap
        case .chooseRoute(let route):
            return state.route?.id != route.id
        case .changeSlippageBps(let slippageBps):
            return state.slippageBps != slippageBps
        }
    }
    
    static func jupiterSwapProgressState(
        state: JupiterSwapState,
        action: JupiterSwapAction
    ) -> JupiterSwapState? {
        #if !RELEASE
        print("JupiterSwapBusinessLogic.action: \(action.description) in progress")
        #endif
        
        switch action {
        case .initialize:
            return .zero.modified { $0.status = .initializing }
        case let .changeAmountFrom(amountFrom):
            return state.modified {
                $0.status = .loadingAmountTo
                $0.route = nil
                $0.swapTransaction = nil
                $0.routes = []
                $0.amountFrom = amountFrom
                $0.amountTo = nil
            }
        case let .changeFromToken(fromToken):
            return state.modified {
                $0.status = .loadingAmountTo
                $0.route = nil
                $0.swapTransaction = nil
                $0.routes = []
                $0.fromToken = fromToken
                $0.amountFrom = nil
                $0.amountTo = nil
            }
        case let .changeToToken(toToken):
            return state.modified {
                $0.status = .loadingAmountTo
                $0.route = nil
                $0.swapTransaction = nil
                $0.routes = []
                $0.toToken = toToken
                $0.amountTo = nil
            }
        case .switchFromAndToTokens:
            return state.modified {
                $0.status = .switching
                $0.route = nil
                $0.swapTransaction = nil
                $0.routes = []
                $0.fromToken = state.toToken
                $0.amountFrom = nil
                $0.toToken = state.fromToken
                $0.amountTo = nil
            }
        case .update:
            return state.modified {
                $0.status = .loadingAmountTo
                $0.route = nil
                $0.swapTransaction = nil
                $0.routes = []
                $0.amountTo = nil
            }
        case .updateUserWallets:
            return state.modified {
                $0.status = .switching
            }
        case .updateTokensPriceMap:
            return nil
        case let .chooseRoute(route):
            return state.modified {
                $0.status = .loadingAmountTo
                $0.route = route
                $0.swapTransaction = nil
                $0.amountTo = UInt64(route.outAmount)?
                    .convertToBalance(decimals: state.toToken.token.decimals)
            }
        case let .changeSlippageBps(slippageBps):
            return state.modified {
                $0.status = .loadingAmountTo
                $0.route = nil
                $0.swapTransaction = nil
                $0.routes = []
                $0.amountTo = nil
                $0.slippageBps = slippageBps
            }
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

        case .changeAmountFrom:
            // recalculate the route and mark status as creatingTransaction
            return await recalculateRouteAndMarkAsCreatingTransaction(
                state: state,
                services: services
            )
        case .changeFromToken:
            // return state as amount from is reset to nil
            return state.modified {
                $0.status = .ready
            }
        case .changeToToken:
            // recalculate route and make transaction if amountFrom > 0
            if state.amountFrom > 0 {
                // recalculate the route and mark status as creatingTransaction
                return await recalculateRouteAndMarkAsCreatingTransaction(
                    state: state,
                    services: services
                )
            }
            
            // else just return current state
            return state.modified {
                $0.status = .ready
            }
            
        case .switchFromAndToTokens:
            return state.modified {
                $0.status = .ready
            }
        case .update:
            // recalculate the route and mark status as creatingTransaction
            return await recalculateRouteAndMarkAsCreatingTransaction(
                state: state,
                services: services
            )
        case let .updateUserWallets(userWallets):
            // get old data
            let oldFromToken = state.fromToken
            let oldToToken = state.toToken
            
            // get new state
            let state = updateUserWallets(state: state, userWallets: userWallets, services: services)
            
            // if fromToken and toToken weren't changed
            if oldFromToken.address == state.fromToken.address && oldToToken.address == state.toToken.address {
                // return the current state with status ready
                return state.modified {
                    $0.status = .ready
                }
            }
            
            // otherwise
            else {
                // recalculate the route and mark status as creatingTransaction
                return await recalculateRouteAndMarkAsCreatingTransaction(
                    state: state,
                    services: services
                )
            }
        case let .updateTokensPriceMap(tokensPriceMap):
            // update tokens price
            return state.modified {
                $0.tokensPriceMap = tokensPriceMap
            }
        case .changeSlippageBps:
            // recalculate the route and mark status as creatingTransaction
            return await recalculateRouteAndMarkAsCreatingTransaction(
                state: state,
                services: services
            )
        case .chooseRoute:
            // create swap transaction
            return state.modified {
                $0.status = .creatingSwapTransaction
            }
        }
    }
    
    static func createTransaction(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        do {
            guard state.status == .creatingSwapTransaction else {
                return state
            }
            
            guard let route = state.route else {
                return state.error(.routeIsNotFound)
            }

            guard let account = state.account else {
                return state.error(.createTransactionFailed)
            }

            let swapTransaction = try await services.jupiterClient.swap(
                route: route,
                userPublicKey: account.publicKey.base58EncodedString,
                wrapUnwrapSol: true,
                feeAccount: nil,
                computeUnitPriceMicroLamports: nil
            )
            
            guard let swapTransaction else {
                throw JupiterError.invalidResponse
            }

            return state.modified {
                $0.status = .ready
                $0.swapTransaction = swapTransaction
            }
        }
        catch let error {
            if (error as NSError).isNetworkConnectionError {
                return state.error(.networkConnectionError)
            }
            return state.error(.createTransactionFailed)
        }
    }
    
    // MARK: - Helpers

    private static func recalculateRouteAndMarkAsCreatingTransaction(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        // recalculate the route
        let state = await calculateRoute(
            state: state,
            services: services
        )
        
        // check if status is ready
        guard state.status == .ready else {
            return state
        }
        
        // mark as creating swap transaction
        return state.modified {
            $0.status = .creatingSwapTransaction
        }
    }
}
