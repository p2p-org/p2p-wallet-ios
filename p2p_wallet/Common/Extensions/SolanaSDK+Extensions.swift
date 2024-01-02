import FirebaseRemoteConfig
import SolanaSwift

extension APIEndPoint {
    static var definedEndpoints: [Self] {
        let remoteEndpoints = RemoteConfig.remoteConfig()
            .definedEndpoints
            .map {
                APIEndPoint(
                    address: $0.urlString ?? "",
                    network: $0.network ?? .mainnetBeta,
                    additionalQuery: .secretConfig($0.additionalQuery ?? "")
                )
            }
        var endpoints = remoteEndpoints.isEmpty ? defaultEndpoints : remoteEndpoints
//        if remoteEndpoints.isEmpty {
        endpoints.insert(
            .init(
                address: "https://solana.keyapp.org",
                network: .mainnetBeta,
                additionalQuery: .secretConfig("KEYAPP_ORG_API_KEY")
            ),
            at: 0
        )
        #if !DEBUG
            endpoints.removeAll { $0.network == .testnet || $0.network == .devnet }
        #endif
//        }
        return endpoints
    }
}
