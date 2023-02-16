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
        } catch {
            return state.copy(status: .error(reason: .coingeckoPriceFailure))
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
        } catch {
            return state.copy(status: .error(reason: .coingeckoPriceFailure))
        }
    }

    static func changeBothTokens(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        fromToken: SwapToken,
        toToken: SwapToken
    ) async -> JupiterSwapState {
        do {
            let newPriceInfo = try await getPrices(from: fromToken, to: toToken, services: services)
            return state.copy(fromToken: fromToken, toToken: toToken, priceInfo: newPriceInfo)
        } catch {
            return state.copy(status: .error(reason: .coingeckoPriceFailure))
        }
    }
}
