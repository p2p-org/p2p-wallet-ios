enum FeeRelayerEndpoint {
    static let baseUrl = "https://\(String.secretConfig("FEE_RELAYER_STAGING_ENDPOINT")!)"
}
