enum FeeRelayerEndpoint {
    static let baseUrl = GlobalAppState.shared.forcedFeeRelayerEndpoint
        .isEmpty ? "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)" : GlobalAppState.shared.forcedFeeRelayerEndpoint
}
