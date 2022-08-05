import Onboarding

protocol OnboardingService {
    var lastState: CreateWalletFlowState? { get }
}

final class OnboardingServiceImpl: OnboardingService {
    var lastState: CreateWalletFlowState?
}
