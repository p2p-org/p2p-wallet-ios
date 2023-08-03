import AnalyticsManager
import FirebaseAnalytics
import Foundation

public final class FirebaseAnalyticsProvider: AnalyticsProvider {
    public var providerId: AnalyticsProviderId {
        KeyAppAnalyticsProviderId.firebaseAnalytics.rawValue
    }

    public init() {}

    public func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.name else { return }
        Analytics.logEvent(
            eventName,
            parameters: event.params
        )
    }

    public func logParameter(_: AnalyticsParameter) {}
}
