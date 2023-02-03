import Foundation
import FirebaseAnalytics
import AnalyticsManager

final class FirebaseAnalyticsProvider: AnalyticsProvider {
    init() {}

    func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        Analytics.logEvent(
            eventName,
            parameters: event.params
        )
    }
}
