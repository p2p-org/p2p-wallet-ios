import Jupiter
import SolanaSwift

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
            return state.amountFrom > 0
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
            return nil
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
        case let .initialize(account, jupiterTokens, routeMap, preChosenFromTokenMintAddress, preChosenToTokenMintAddress):
            return await initializeAction(
                state: state,
                services: services,
                account: account,
                jupiterTokens: jupiterTokens,
                routeMap: routeMap,
                preChosenFromTokenMintAddress: preChosenFromTokenMintAddress,
                preChosenToTokenMintAddress: preChosenToTokenMintAddress
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
            // get new state
            return updateUserWallets(state: state, userWallets: userWallets, services: services)
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
            let state = await validateAmounts(
                state: state,
                services: services
            )
            
            // ready for creating transaction
            if state.status == .ready {
                return state.modified {
                    $0.status = .creatingSwapTransaction
                }
            }
            
            return state
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

            guard var route = state.route else {
                return state.error(.routeIsNotFound)
            }

            guard let account = state.account else {
                return state.error(.createTransactionFailed)
            }

            var availableRoutes = state.routes
            if let index = availableRoutes.firstIndex(where: { $0.id == route.id }), index == 0 {
                var swapTransaction: String?
                var failedRoutes = [Route]()
                for availableRoute in availableRoutes {
                    // Try create and simulate transaction to see if it works correctly
                    swapTransaction = try await createAndSimulateTransaction(for: availableRoute, account: account, services: services)

                    if swapTransaction == nil {
                        failedRoutes.append(availableRoute)
                    } else {
                        route = availableRoute
                        // We found the best route and do not need to create transaction anymore
                        break
                    }
                }

                // Remove failed routes from the state
                failedRoutes.forEach { failedRoute in
                    availableRoutes.removeAll(where: { $0.id == failedRoute.id })
                }

                if let swapTransaction {
                    return state.modified {
                        $0.route = route
                        $0.routes = availableRoutes // Replace routes only with available ones
                        $0.status = .ready
                        $0.swapTransaction = swapTransaction
                    }
                } else {
                    // If there is no swapTransaction, then the state is "routeIsNotFound"
                    return state.modified {
                        $0.route = nil
                        $0.routes = []
                        $0.status = .error(reason: .routeIsNotFound)
                        $0.swapTransaction = nil
                    }
                }
            } else {
                // If route is chosen by user and is not the best one, just try create transaction without simulation
                let swapTransaction = try await createTransaction(for: route, account: account, services: services)
                return state.modified {
                    $0.status = .ready
                    $0.swapTransaction = swapTransaction
                }
            }
        }
        catch let error {
            if (error as NSError).isNetworkConnectionError {
                return state.error(.networkConnectionError)
            }
            return state.error(.createTransactionFailed)
        }
    }

    // MARK: - Private

    private static func createTransaction(
        for route: Route,
        account: KeyPair,
        services: JupiterSwapServices
    ) async throws -> String {
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

        return swapTransaction
    }

    private static func createAndSimulateTransaction(
        for route: Route,
        account: KeyPair,
        services: JupiterSwapServices
    ) async throws -> String? {
        do {
            let swapTransaction = try await services.jupiterClient.swap(
                route: route,
                userPublicKey: account.publicKey.base58EncodedString,
                wrapUnwrapSol: true,
                feeAccount: nil,
                computeUnitPriceMicroLamports: nil
            )

            guard let swapTransaction else { return nil }

            let simulation = try await services.solanaAPIClient.simulateTransaction(
                transaction: swapTransaction,
                configs: RequestConfiguration(encoding: "base64")!
            )

            if simulation.err == nil {
                return swapTransaction
            } else {
                return nil
            }
        } catch let error {
            if (error as NSError).isNetworkConnectionError {
                throw error
            }
            return nil // If simulation or transaction fails, then we skip this route and return nil
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
