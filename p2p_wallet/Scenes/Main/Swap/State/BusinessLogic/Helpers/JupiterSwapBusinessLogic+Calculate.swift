import Jupiter
import SolanaSwift
import Resolver
import SolanaPricesAPIs

extension JupiterSwapBusinessLogic {
    static func calculateRoute(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        // get current from amount
        guard let amountFrom = state.amountFrom, amountFrom > 0
        else {
            return state.modified {
                $0.status = .ready
            }
        }
        
        // assert from token is not equal to toToken
        guard state.fromToken.address != state.toToken.address else {
            return state.error(.equalSwapTokens)
        }

        // get lamport
        let amountFromLamports = amountFrom
            .toLamport(decimals: state.fromToken.token.decimals)

        do {
            // call api to get routes and amount
            let data = try await services.jupiterClient.quote(
                inputMint: state.fromToken.address,
                outputMint: state.toToken.address,
                amount: String(amountFromLamports),
                swapMode: nil,
                slippageBps: state.slippageBps,
                feeBps: nil,
                onlyDirectRoutes: nil,
                userPublicKey: state.account?.publicKey.base58EncodedString,
                enforceSingleTx: nil
            )
            
            // routes
            let routes = data.data
            
            // if pre chosen route is stil available, choose it
            // if not choose the first one
            guard let route = (data.data?.first { $0.id == state.route?.id } ?? data.data?.first) else {
                let status: JupiterSwapState.Status
                if let errorMessage = data.message,
                    errorMessage.contains("The value \"NaN\" cannot be converted to a number") {
                    status = .error(reason: .minimumAmount)
                } else {
                    status = .error(reason: .routeIsNotFound)
                }
                return state.modified {
                    $0.status = status
                    $0.routes = routes ?? []
                    $0.route = nil
                }
            }

            return await validateAmounts(
                state: state.modified {
                    $0.status = .ready
                    $0.route = route
                    $0.routes = routes ?? []
                    $0.amountTo = UInt64(route.outAmount)?
                        .convertToBalance(decimals: state.toToken.token.decimals)
                },
                services: services
            )
        }
        catch let error {
            return handle(error: error, for: state)
        }
    }

    private static func handle(error: Error, for state: JupiterSwapState) -> JupiterSwapState {
        if (error as NSError).isNetworkConnectionError {
            return state.error(.networkConnectionError(.gettingRoute))
        } else if (error as NSError).domain.contains("The value \"NaN\" cannot be converted to a number") {
            return state.error(.minimumAmount)
        }
        debugPrint("---error: ", error.readableDescription)
        return state.error(.routeIsNotFound)
    }

    static func validateAmounts(state: JupiterSwapState, services: JupiterSwapServices) async -> JupiterSwapState {
        let status: JupiterSwapState.Status

        if let balance = state.fromToken.userWallet?.amount {
            if state.amountFrom > balance {
                status = .error(reason: .notEnoughFromToken)
            } else if state.fromToken.address == Token.nativeSolana.address {
                status = await validateNativeSOL(balance: balance, state: state, services: services)
            } else {
                status = .ready
            }
        } else {
            status = .error(reason: .notEnoughFromToken)
        }

        return state.modified { $0.status = status }
    }

    private static func validateNativeSOL(balance: Double, state: JupiterSwapState, services: JupiterSwapServices) async -> JupiterSwapState.Status {
        guard let amountFrom = state.amountFrom else {
            return .error(reason: .routeIsNotFound)
        }
        do {
            let decimals = state.fromToken.token.decimals
            let minBalance = try await services.relayContextManager.getCurrentContextOrUpdate().minimumRelayAccountBalance
            let remains = (balance - amountFrom).toLamport(decimals: decimals)
            if remains > 0 && remains < minBalance {
                let maximumInput = (balance.toLamport(decimals: decimals) - minBalance).convertToBalance(decimals: decimals)
                return .error(reason: .inputTooHigh(maximumInput))
            } else {
                return .ready
            }
        } catch {
            return .error(reason: .networkConnectionError(.gettingRoute))
        }
    }
}
