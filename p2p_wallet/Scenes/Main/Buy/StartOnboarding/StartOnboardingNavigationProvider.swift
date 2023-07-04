import Onboarding
import Resolver
import UIKit
import AnalyticsManager

protocol StartOnboardingNavigationProvider {
    func startCoordinator(for window: UIWindow) -> Coordinator<OnboardingResult>
}

final class StartOnboardingNavigationProviderImpl: StartOnboardingNavigationProvider {
    @Injected private var service: OnboardingService
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var deviceShareManager: DeviceShareManager
    
    @MainActor func startCoordinator(for window: UIWindow) -> Coordinator<OnboardingResult> {
        let isDeviceShareAvailable = deviceShareManager.deviceShare != nil
        analyticsManager.log(parameter: .userDeviceshare(isDeviceShareAvailable))

        if isDeviceShareAvailable {
            return RestoreWalletCoordinator(navigation: .root(window: window))
        } else if service.lastState != nil {
            return ContinueCoordinator(window: window)
        } else {
            return StartCoordinator(window: window)
        }
    }
}
