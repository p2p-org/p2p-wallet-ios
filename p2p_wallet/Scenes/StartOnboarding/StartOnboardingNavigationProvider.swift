import Onboarding
import Resolver
import UIKit
import AnalyticsManager

protocol StartOnboardingNavigationProvider {
    func startCoordinator(for window: UIWindow) -> Coordinator<OnboardingResult>
}

final class StartOnboardingNavigationProviderImpl: StartOnboardingNavigationProvider {
    @Injected private var service: OnboardingService
    @Injected private var accountStorage: AccountStorageType
    @Injected private var amplitudeAnalyticsProvider: AmplitudeAnalyticsProvider

    @MainActor func startCoordinator(for window: UIWindow) -> Coordinator<OnboardingResult> {
        let isDeviceShareAvailable = accountStorage.deviceShare != nil
        amplitudeAnalyticsProvider.setIdentifier(AmplitudeIdentifier.userDeviceshare(deviceshare: isDeviceShareAvailable))

        if isDeviceShareAvailable {
            return RestoreWalletCoordinator(navigation: .root(window: window))
        } else if service.lastState != nil {
            return ContinueCoordinator(window: window)
        } else {
            return StartCoordinator(window: window)
        }
    }
}
