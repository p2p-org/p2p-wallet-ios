import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func changeFromToken(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        token: SwapToken
    ) async -> JupiterSwapState {
        do {
            let priceFromToken = try await getPrices(for: token, services: services)
            let newPriceInfo = SwapPriceInfo(fromPrice: priceFromToken ?? 0, toPrice: state.priceInfo.toPrice)
            return state.copy(fromToken: token, priceInfo: newPriceInfo)
        } catch let error {
            return handle(error: error, for: state)
        }
    }

    static func changeToToken(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        token: SwapToken
    ) async -> JupiterSwapState {
        do {
            let priceToToken = try await getPrices(for: token, services: services)
            let newPriceInfo = SwapPriceInfo(fromPrice: state.priceInfo.fromPrice, toPrice: priceToToken ?? 0)
            return state.copy(toToken: token, priceInfo: newPriceInfo)
        } catch let error {
            return handle(error: error, for: state)
        }
    }

    static func switchFromAndToTokens(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        do {
            let newFromToken = state.toToken
            let newToToken = state.fromToken
            let newPriceInfo = try await getPrices(from: newFromToken, to: newToToken, services: services)
            return state.copy(fromToken: newFromToken, toToken: newToToken, priceInfo: newPriceInfo)
        } catch let error {
            return handle(error: error, for: state)
        }
    }

    private static func handle(error: Error, for state: JupiterSwapState) -> JupiterSwapState {
        if (error as NSError).isNetworkConnectionError {
            return state.copy(status: .error(reason: .networkConnectionError))
        }
        return state.copy(status: .error(reason: .coingeckoPriceFailure))
    }
}
