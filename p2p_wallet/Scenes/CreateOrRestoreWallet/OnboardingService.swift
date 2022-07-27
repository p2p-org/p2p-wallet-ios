import Onboarding

protocol OnboardingService {
    var lastState: CreateWalletState? { get }
}

final class OnboardingServiceImpl: OnboardingService {
    var lastState: CreateWalletState?
}
