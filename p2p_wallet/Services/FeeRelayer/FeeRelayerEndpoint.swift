enum FeeRelayerEndpoint {
    static let baseUrl = "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)"
}
