import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func changeSlippage(
        state: JupiterSwapState,
        slippageBps: Int
    ) -> JupiterSwapState {
        state.copy(slippageBps: slippageBps)
    }
}
