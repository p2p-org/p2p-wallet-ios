import Onboarding
import Resolver
import UIKit

protocol StartOnboardingNavigationProvider {
    func startCoordinator(for window: UIWindow) -> Coordinator<OnboardingResult>
}

final class StartOnboardingNavigationProviderImpl: StartOnboardingNavigationProvider {
    @Injected var service: OnboardingService
    @Injected var accountStorage: AccountStorageType

    @MainActor func startCoordinator(for window: UIWindow) -> Coordinator<OnboardingResult> {
        if accountStorage.deviceShare != nil {
            return RestoreWalletCoordinator(navigation: .root(window: window))
        } else if let lastState = service.lastState {
            return ContinueCoordinator(window: window)
        } else {
            return StartCoordinator(window: window)
        }
    }
}
