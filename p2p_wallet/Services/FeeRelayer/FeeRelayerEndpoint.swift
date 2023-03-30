enum FeeRelayerEndpoint {
    static var baseUrl: String {
        if let forcedUrl = GlobalAppState.shared.forcedFeeRelayerEndpoint {
            return forcedUrl
        } else {
            switch Environment.current {
            case .release, .test:
                return "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)"
            default:
                return "https://\(String.secretConfig("FEE_RELAYER_STAGING_ENDPOINT")!)"
            }
        }
    }
}
