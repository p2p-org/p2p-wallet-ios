import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func getPrices(from: SwapToken, to: SwapToken, services: JupiterSwapServices) async throws -> SwapPriceInfo? {
        let fromToken = from.token
        let toToken = to.token

        let prices = try await services.pricesAPI.getCurrentPrices(coins: [fromToken, toToken], toFiat: Defaults.fiat.code)
        return SwapPriceInfo(fromPrice: prices[fromToken]??.value ?? 0, toPrice: prices[toToken]??.value ?? 0)
    }

    static func getPrices(for swapToken: SwapToken, services: JupiterSwapServices) async throws -> Double? {
        let token = swapToken.token
        let prices = try await services.pricesAPI.getCurrentPrices(coins: [token], toFiat: Defaults.fiat.code)
        return prices[token]??.value
    }
}
