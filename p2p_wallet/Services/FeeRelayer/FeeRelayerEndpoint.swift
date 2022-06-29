enum FeeRelayerEndpoint {
    static let stageBaseUrl = "https://\(String.secretConfig("FEE_RELAYER_STAGING_ENDPOINT")!)"
    static let prodBaseUrl = "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)"
}
