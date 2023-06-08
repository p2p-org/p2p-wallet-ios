import Onboarding
import Resolver

protocol OnboardingStateMachineProvider {
    func createTKeyFacade() -> TKeyFacade
}

final class OnboardingStateMachineProviderImpl: OnboardingStateMachineProvider {
    @Injected var facadeManager: TKeyFacadeManager

    func createTKeyFacade() -> TKeyFacade {
        if available(.mockedTKeyFacade) {
            return TKeyMockupFacade()
        } else {
            return facadeManager.create(
                BackgroundWebViewManager.requestWebView(),
                with: TKeyJSFacadeConfiguration(
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
                )
            )
        }
    }
}
