import Onboarding

protocol OnboardingService: AnyObject {
    var lastState: CreateWalletFlowState? { get set }
}

final class OnboardingServiceImpl: OnboardingService {
    var lastState: CreateWalletFlowState? {
        get { Defaults.onboardingLastState }
        set { Defaults.onboardingLastState = newValue }
    }
}
