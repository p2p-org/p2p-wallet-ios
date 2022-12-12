enum FeeRelayerEndpoint {
    static var baseUrl: String { GlobalAppState.shared.forcedFeeRelayerEndpoint
        .isEmpty ? "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)" : GlobalAppState.shared.forcedFeeRelayerEndpoint }
}
