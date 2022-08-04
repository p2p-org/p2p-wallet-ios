import Resolver
import UIKit

protocol StartOnboardingNavigationProvider {
    func startCoordinator(for window: UIWindow) -> Coordinator<Void>
}

final class StartOnboardingNavigationProviderImpl: StartOnboardingNavigationProvider {
    @Injected var service: OnboardingService

    @MainActor func startCoordinator(for window: UIWindow) -> Coordinator<Void> {
        if let lastState = service.lastState {
            return ContinueCoordinator(window: window)
        } else {
            return StartCoordinator(navigation: .root(window: window))
        }
    }
}
