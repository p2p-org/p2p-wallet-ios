enum FeeRelayerEndpoint {
    static var baseUrl: String {
        if let forcedUrl = GlobalAppState.shared.forcedFeeRelayerEndpoint {
            return forcedUrl
        } else {
            return "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)"
        }
    }
}
