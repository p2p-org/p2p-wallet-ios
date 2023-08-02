import AnalyticsManager
import AppsFlyerLib
import Foundation

public final class AppsFlyerAnalyticsProvider: NSObject, AnalyticsProvider {
    public var providerId: AnalyticsProviderId {
        KeyAppAnalyticsProviderId.appsFlyer.rawValue
    }

    public func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.name else { return }
        AppsFlyerLib.shared().logEvent(
            name: eventName,
            values: event.params,
            completionHandler: { (response: [String: Any]?, error: Error?) in
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

    public func logParameter(_: AnalyticsParameter) {}
}
