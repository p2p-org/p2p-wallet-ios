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
                    verifierStrategyResolver: { authProvider in
                        switch authProvider {
                        case "google":
                            return .aggregate(
                                verifier: "key-app-google-testnet",
                                subVerifier: "ios"
                            )
                        case "apple":
                            return .single(
                                verifier: OnboardingConfig.shared.torusAppleVerifier
                            )
                        default:
                            fatalError("Invalid")
                        }
                    }
                )
            )
        return tKeyFacade
    }
}
