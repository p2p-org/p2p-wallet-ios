import Onboarding

protocol OnboardingStateMachineProvider {
    func createTKeyFacade() -> TKeyFacade
}

final class OnboardingStateMachineProviderImpl: OnboardingStateMachineProvider {
    func createTKeyFacade() -> TKeyFacade {
        let tKeyFacade: TKeyFacade = available(.mockedTKeyFacade) ?
            TKeyMockupFacade() :
            TKeyJSFacade(
                wkWebView: GlobalWebView.requestWebView(),
                config: .init(
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
}
