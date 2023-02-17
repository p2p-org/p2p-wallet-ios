import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func changeAmountFrom(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        amountFrom: Double
    ) async -> JupiterSwapState {
        return state.copy(amountFrom: amountFrom)
    }
}
