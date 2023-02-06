import Amplitude
import Foundation
import AnalyticsManager

final class AmplitudeAnalyticsProvider: AnalyticsProvider {
    var providerId: AnalyticsProviderId {
        KeyAppAnalyticsProviderId.amplitude.rawValue
    }
    
    init(apiKey: String) {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(apiKey)
    }

    func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.name else { return }
        Amplitude.instance().logEvent(eventName, withEventProperties: event.params)
    }
}
