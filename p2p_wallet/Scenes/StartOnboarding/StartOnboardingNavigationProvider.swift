import Resolver
import UIKit

protocol StartOnboardingNavigationProvider {
    func startCoordinator(for window: UIWindow) -> Coordinator<Void>
}

final class StartOnboardingNavigationProviderImpl: StartOnboardingNavigationProvider {
    @Injected var service: OnboardingService

    @MainActor func startCoordinator(for window: UIWindow) -> Coordinator<Void> {
        switch service.lastState {
        case .enterPhoneNumber, .verifyPhoneNumber, .enterPincode:
            return ContinueCoordinator(window: window)
        default:
            return StartCoordinator(navigation: .root(window: window))
        }
    }
}
