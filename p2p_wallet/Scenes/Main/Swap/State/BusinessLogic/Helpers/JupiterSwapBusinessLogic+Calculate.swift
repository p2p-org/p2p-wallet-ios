import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func calculateAmounts(state: JupiterSwapState, services: JupiterSwapServices) async -> JupiterSwapState {
        guard state.fromToken.address != state.toToken.address else {
            return state.copy(status: .error(reason: .equalSwapTokens))
        }

        guard state.amountFrom > 0 else {
            return state.copy(status: .ready, amountFrom: 0, amountFromFiat: 0, amountTo: 0, route: nil)
        }

        let amountFromLamports = state.amountFrom.toLamport(decimals: state.fromToken.token.decimals)

        do {
            let data = try await services.jupiterClient.quote(
                inputMint: state.fromToken.address,
                outputMint: state.toToken.address,
                amount: String(amountFromLamports),
                swapMode: nil,
                slippageBps: state.slippage,
                feeBps: nil,
                onlyDirectRoutes: nil,
                userPublicKey: nil,
                enforceSingleTx: nil
            )

            guard let route = data.data.first, let toAmountLamports = Lamports(route.outAmount) else {
                return state.copy(status: .error(reason: .routeIsNotFound))
            }

            let amountTo = toAmountLamports.convertToBalance(decimals: state.toToken.token.decimals)
            let newPriceInfo = SwapPriceInfo(
                fromPrice: state.priceInfo.fromPrice,
                toPrice: state.priceInfo.toPrice,
                relation: Double(state.amountFrom/amountTo)
            )

            return await validateAmounts(state: state.copy(status: .ready, amountTo: amountTo, priceInfo: newPriceInfo, route: route), services: services)
        }
        catch let error {
            return handle(error: error, for: state)
        }
    }

    private static func handle(error: Error, for state: JupiterSwapState) -> JupiterSwapState {
        if (error as NSError).isNetworkConnectionError {
            return state.copy(status: .error(reason: .networkConnectionError))
        }
        return state.copy(status: .error(reason: .routeIsNotFound))
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

        return state.copy(status: status)
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
