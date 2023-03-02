import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func changeSlippage(
        state: JupiterSwapState,
        slippage: Int
    ) -> JupiterSwapState {
        state.copy(slippage: slippage)
    }
}
