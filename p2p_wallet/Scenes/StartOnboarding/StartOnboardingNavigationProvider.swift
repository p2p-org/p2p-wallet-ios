import Onboarding
import Resolver
import UIKit

protocol StartOnboardingNavigationProvider {
    func startCoordinator(for window: UIWindow) -> Coordinator<OnboardingResult>
}

final class StartOnboardingNavigationProviderImpl: StartOnboardingNavigationProvider {
    @Injected var service: OnboardingService

    @MainActor func startCoordinator(for window: UIWindow) -> Coordinator<OnboardingResult> {
        if let lastState = service.lastState {
            return ContinueCoordinator(window: window)
        } else {
            return StartCoordinator(window: window)
        }
    }
}
