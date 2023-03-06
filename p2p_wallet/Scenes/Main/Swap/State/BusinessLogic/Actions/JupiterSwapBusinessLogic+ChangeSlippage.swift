import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func changeSlippage(
        state: JupiterSwapState,
        slippageBps: Int,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        // assert changes
        guard state.slippageBps != slippageBps else {
            return state
        }
        
        // slippage has changed, must re-calculate the amount
        let state = state.copy(slippageBps: slippageBps)
        return await calculateToAmountAndFees(state: state, services: services)
    }
}
