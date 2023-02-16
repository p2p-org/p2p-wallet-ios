import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func changeAmountFrom(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        amountFrom: Double
    ) async -> JupiterSwapState {
        do {
            guard amountFrom > 0 else {
                return state.copy(amountFrom: 0, amountTo: 0, route: nil)
            }

            let amountFromLamports = amountFrom.toLamport(decimals: state.fromToken.jupiterToken.decimals)

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
                throw JupiterSwapState.ErrorReason.routeIsNotFound
            }

            let toAmount = toAmountLamports.convertToBalance(decimals: state.toToken.jupiterToken.decimals)
            let newPriceInfo = SwapPriceInfo(
                fromPrice: state.priceInfo.fromPrice,
                toPrice: state.priceInfo.toPrice,
                relation: Double(toAmount/amountFrom)
            )

            return state.copy(amountFrom: amountFrom, amountTo: toAmount, priceInfo: newPriceInfo, route: route)
        } catch {
            return state.copy(status: .error(reason: .unknown))
        }
        
    }
}
