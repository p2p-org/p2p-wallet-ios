import Jupiter
import SolanaSwift
import Resolver
import SolanaPricesAPIs

extension JupiterSwapBusinessLogic {
    static func calculateRoute(
        state: JupiterSwapState,
        newFromAmount: Double? = nil,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        // assert from token is not equal to toToken
        guard state.fromToken.address != state.toToken.address else {
            return state.error(.equalSwapTokens)
        }

        // assert amountFrom is not 0
        let amountFrom = newFromAmount ?? state.amountFrom
        guard amountFrom > 0
        else {
            return state.modified {
                $0.status = .ready
                $0.route = nil
            }
        }

        // get lamport
        let amountFromLamports = amountFrom.toLamport(decimals: state.fromToken.token.decimals)

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
            guard let route = data.data.first(
                where: {$0.id == state.route?.id})
                    ?? data.data.first
            else {
                return state.modified {
                    $0.status = .error(reason: .routeIsNotFound)
                    $0.route = nil
                }
            }
            
            // get all tokens that involved in the swap and get the price
            var tokens = [Token]()
            tokens.append(state.fromToken.token)
            tokens.append(state.toToken.token)
            
            // get prices of transitive tokens
            let mints = route.getMints()
            if mints.count > 2 {
                for mint in mints {
                    if let token = state.swapTokens.map(\.token).first(where: {$0.address == mint}) {
                        tokens.append(token)
                    }
                }
            }
            
            let tokensPriceMap = ((try? await services.pricesAPI.getCurrentPrices(coins: tokens, toFiat: Defaults.fiat.symbol)) ?? [:])
                .reduce([String: Double]()) { combined, element in
                    guard let value = element.value?.value else { return combined }
                    var combined = combined
                    combined[element.key.address] = value
                    return combined
                }

            return await validateAmounts(
                state: state.modified {
                    $0.status = .ready
                    $0.route = route
                    $0.routes = routes
                    $0.tokensPriceMap = $0.tokensPriceMap
                        .merging(tokensPriceMap, uniquingKeysWith: { (_, new) in new })
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
            return state.error(.networkConnectionError)
        }
        return state.error(.routeIsNotFound)
    }

    private static func validateAmounts(state: JupiterSwapState, services: JupiterSwapServices) async -> JupiterSwapState {
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
        do {
            let decimals = state.fromToken.token.decimals
            let minBalance = try await services.relayContextManager.getCurrentContextOrUpdate().minimumRelayAccountBalance
            let remains = (balance - state.amountFrom).toLamport(decimals: decimals)
            if remains > 0 && remains < minBalance {
                let maximumInput = (balance.toLamport(decimals: decimals) - minBalance).convertToBalance(decimals: decimals)
                return .error(reason: .inputTooHigh(maximumInput))
            } else {
                return .ready
            }
        } catch {
            return .error(reason: .networkConnectionError)
        }
    }
}
