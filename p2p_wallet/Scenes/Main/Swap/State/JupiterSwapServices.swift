import FeeRelayerSwift
import Jupiter
import KeyAppBusiness
import SolanaSwift

struct JupiterSwapServices {
    let jupiterClient: JupiterAPI
    let pricesAPI: PriceService
    let solanaAPIClient: SolanaAPIClient
    let relayContextManager: RelayContextManager
}
