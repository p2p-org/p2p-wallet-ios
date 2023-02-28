import SolanaPricesAPIs
import SolanaSwift
import Jupiter
import FeeRelayerSwift

struct JupiterSwapServices {
    let jupiterClient: JupiterAPI
    let pricesAPI: SolanaPricesAPI
    let solanaAPIClient: SolanaAPIClient
    let relayContextManager: RelayContextManager
}
