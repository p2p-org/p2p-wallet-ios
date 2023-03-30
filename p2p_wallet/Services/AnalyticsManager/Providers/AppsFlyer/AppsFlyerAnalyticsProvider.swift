import AppsFlyerLib
import Foundation
import AnalyticsManager

final class AppsFlyerAnalyticsProvider: NSObject, AnalyticsProvider {
    var providerId: AnalyticsProviderId {
        KeyAppAnalyticsProviderId.appsFlyer.rawValue
    }
    
    override init() {
        #if DEBUG
            AppsFlyerLib.shared().isDebug = true
        #endif

        super.init()

        AppsFlyerLib.shared().deepLinkDelegate = self
    }

    func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.name else { return }
        AppsFlyerLib.shared().logEvent(
            name: eventName,
            values: event.params,
            completionHandler: { (response: [String : Any]?, error: Error?) in
                if let response = response {
                    #if !RELEASE
                    print("In app event callback Success: ", response)
                    #endif
                }
                if let error = error {
                    #if !RELEASE
                    print("In app event callback ERROR:", error)
                    #endif
                }
            }
        )
    }
    
    func logParameter(_ parameter: AnalyticsParameter) {}
}

// MARK: - DeepLinkDelegate

extension AppsFlyerAnalyticsProvider: DeepLinkDelegate {
    func didResolveDeepLink(_: DeepLinkResult) {}
}
