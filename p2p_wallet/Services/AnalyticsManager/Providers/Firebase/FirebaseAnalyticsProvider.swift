import Foundation
import FirebaseAnalytics
import AnalyticsManager

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
}
