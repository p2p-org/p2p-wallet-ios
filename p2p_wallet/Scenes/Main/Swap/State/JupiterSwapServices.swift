import SolanaPricesAPIs
import Jupiter

struct JupiterSwapServices {
    let jupiterClient: JupiterAPI
    let pricesAPI: SolanaPricesAPI

    init(jupiterClient: JupiterAPI, pricesAPI: SolanaPricesAPI) {
        self.jupiterClient = jupiterClient
        self.pricesAPI = pricesAPI
    }
}
