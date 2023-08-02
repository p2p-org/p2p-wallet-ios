import Amplitude
import AnalyticsManager
import Foundation

public final class AmplitudeAnalyticsProvider: AnalyticsProvider {
    public var providerId: AnalyticsProviderId {
        KeyAppAnalyticsProviderId.amplitude.rawValue
    }

    public init(apiKey: String) {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(apiKey)
    }

    public func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.name else { return }
        Amplitude.instance().logEvent(eventName, withEventProperties: event.params)
    }

    public func logParameter(_ parameter: AnalyticsParameter) {
        guard
            let value = parameter.value as? NSObject,
            let identify = AMPIdentify().set(parameter.name, value: value)
        else { return }
        Amplitude.instance().identify(identify)
    }
}
