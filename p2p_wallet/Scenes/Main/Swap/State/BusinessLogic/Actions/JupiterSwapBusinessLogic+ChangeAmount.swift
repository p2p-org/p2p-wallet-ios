import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func changeAmountFrom(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        amountFrom: Double
    ) async -> JupiterSwapState {
        // TODO: In progress
        let toAmount = amountFrom * state.priceInfo.relation
        return state.copy(amountFrom: amountFrom, amountTo: toAmount)
    }
}
