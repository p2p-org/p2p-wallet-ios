import Onboarding
import Resolver

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
                    torusNetwork: OnboardingConfig.shared.torusNetwork,
                    verifierStrategyResolver: { authProvider in
                        switch authProvider {
                        case "google":
                            return .aggregate(
                                verifier: OnboardingConfig.shared.torusGoogleVerifier,
                                subVerifier: OnboardingConfig.shared.torusGoogleSubVerifier
                            )
                        case "apple":
                            return .single(
                                verifier: OnboardingConfig.shared.torusAppleVerifier
                            )
                        default:
                            fatalError("Invalid")
                        }
                    }
                ),
                analyticsManager: Resolver.resolve()
            )
        return tKeyFacade
    }
}
