enum FeeRelayerEndpoint {
    static var baseUrl: String {
        if let forcedUrl = GlobalAppState.shared.forcedFeeRelayerEndpoint {
            return forcedUrl
        } else {
            if Environment.current == .release {
                return "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)"
            } else {
                return "https://\(String.secretConfig("FEE_RELAYER_STAGING_ENDPOINT")!)"
            }
        }
    }
}
