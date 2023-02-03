import Amplitude
import Foundation
import AnalyticsManager

final class AmplitudeAnalyticsProvider: AnalyticsProvider {
    init(apiKey: String) {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(apiKey)
    }

    func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.eventName else { return }
        Amplitude.instance().logEvent(eventName, withEventProperties: event.params)
    }
}
