import AnalyticsManager
import FirebaseAnalytics
import Foundation

final class FirebaseAnalyticsProvider: AnalyticsProvider {
    var providerId: AnalyticsProviderId {
        KeyAppAnalyticsProviderId.firebaseAnalytics.rawValue
    }

    init() {}

    func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.name else { return }
        Analytics.logEvent(
            eventName,
            parameters: event.params
        )
    }

    func logParameter(_: AnalyticsParameter) {}
}
