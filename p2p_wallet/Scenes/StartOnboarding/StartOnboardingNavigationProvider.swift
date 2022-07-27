import Resolver
import UIKit

protocol StartOnboardingNavigationProvider {
    func startCoordinator(for window: UIWindow) -> Coordinator<Void>
}

final class StartOnboardingNavigationProviderImpl: StartOnboardingNavigationProvider {
    @Injected var service: OnboardingService

    @MainActor func startCoordinator(for window: UIWindow) -> Coordinator<Void> {
        switch service.lastState {
        case .enterPhoneNumber, .verifyPhoneNumber:
            return ContinueCoordinator(window: window)
        case .enterPincode, .socialSignIn, .socialSignInUnhandleableError, .finish, .finishWithoutResult:
            return StartCoordinator(navigation: .root(window: window))
        case .none:
            return StartCoordinator(navigation: .root(window: window))
        }
    }
}
