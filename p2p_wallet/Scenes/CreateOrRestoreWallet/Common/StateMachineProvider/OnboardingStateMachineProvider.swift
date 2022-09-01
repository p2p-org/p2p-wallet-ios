import Onboarding

protocol OnboardingStateMachineProvider {
    func createTKeyFacade() -> TKeyFacade
    func createApiGatewayClient() -> APIGatewayClient
}

final class OnboardingStateMachineProviderImpl: OnboardingStateMachineProvider {
    func createTKeyFacade() -> TKeyFacade {
        let tKeyFacade: TKeyFacade = available(.mockedTKeyFacade) ?
            TKeyMockupFacade() :
            TKeyJSFacade(
                wkWebView: GlobalWebView.requestWebView(),
                config: .init(
                    metadataEndpoint: OnboardingConfig.shared.metaDataEndpoint,
                    torusEndpoint: OnboardingConfig.shared.torusEndpoint,
                    torusNetwork: "testnet",
                    torusVerifierMapping: [
                        "google": OnboardingConfig.shared.torusGoogleVerifier,
                        "apple": OnboardingConfig.shared.torusAppleVerifier,
                    ]
                )
            )
        return tKeyFacade
    }

    func createApiGatewayClient() -> APIGatewayClient {
        #if !RELEASE
            let apiGatewayEndpoint = String.secretConfig("API_GATEWAY_DEV")!
        #else
            let apiGatewayEndpoint = String.secretConfig("API_GATEWAY_PROD")!
        #endif

        let apiGatewayClient: APIGatewayClient = available(.mockedApiGateway) ?
            APIGatewayClientImplMock() :
            APIGatewayClientImpl(endpoint: apiGatewayEndpoint)
        return apiGatewayClient
    }
}
