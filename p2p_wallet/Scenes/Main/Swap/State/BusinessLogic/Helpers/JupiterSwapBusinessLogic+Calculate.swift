import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func calculateAmounts(state: JupiterSwapState, services: JupiterSwapServices) async -> JupiterSwapState {
        guard state.fromToken.jupiterToken.address != state.toToken.jupiterToken.address else {
            return state.copy(status: .error(reason: .equalSwapTokens))
        }

        guard state.amountFrom > 0 else {
            return state.copy(status: .ready, amountFrom: 0, amountTo: 0, route: nil)
        }

        let amountFromLamports = state.amountFrom.toLamport(decimals: state.fromToken.jupiterToken.decimals)

        do {
            let data = try await services.jupiterClient.quote(
                inputMint: state.fromToken.jupiterToken.address,
                outputMint: state.toToken.jupiterToken.address,
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

            let amountTo = toAmountLamports.convertToBalance(decimals: state.toToken.jupiterToken.decimals)
            let newPriceInfo = SwapPriceInfo(
                fromPrice: state.priceInfo.fromPrice,
                toPrice: state.priceInfo.toPrice,
                relation: Double(state.amountFrom/amountTo)
            )

            let status: JupiterSwapState.Status
            if let userWallet = state.fromToken.userWallet {
                if state.amountFrom > userWallet.amount {
                    status = .error(reason: .notEnoughFromToken)
                } else {
                    status = .ready
                }
            } else {
                status = .error(reason: .notEnoughFromToken)
            }

            return state.copy(status: status, amountTo: amountTo, priceInfo: newPriceInfo, route: route)
        }
        catch {
            return state.copy(status: .error(reason: .unknown))
        }
    }
}
