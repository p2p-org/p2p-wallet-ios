import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func changeAmountFrom(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        amountFrom: Double
    ) async -> JupiterSwapState {
        let amountFiat = state.priceInfo.fromPrice * amountFrom
        return state.copy(amountFrom: amountFrom, amountFromFiat: amountFiat)
    }
}
