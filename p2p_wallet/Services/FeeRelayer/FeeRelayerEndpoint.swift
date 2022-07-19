import SwiftyUserDefaults

enum FeeRelayerEndpoint {
    static let baseUrl = "https://\(String.secretConfig(Defaults.feeRelayerConfigPath)!)"
}
