import Amplitude
import Foundation
import AnalyticsManager

final class AmplitudeAnalyticsProvider: AnalyticsProvider {
    var providerId: AnalyticsProviderId {
        KeyAppAnalyticsProviderId.amplitude.rawValue
    }
    
    init() {
        let apiKey: String
        #if !RELEASE
        apiKey = .secretConfig("AMPLITUDE_API_KEY_FEATURE")!
        #else
        apiKey = .secretConfig("AMPLITUDE_API_KEY")!
        #endif
        
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(apiKey)
    }

    func logEvent(_ event: AnalyticsEvent) {
        guard let eventName = event.name else { return }
        Amplitude.instance().logEvent(eventName, withEventProperties: event.params)
    }
    
    func logParameter(_ parameter: AnalyticsParameter) {
        guard
            let value = parameter.value as? NSObject,
            let identify = AMPIdentify().set(parameter.name, value: value)
        else { return }
        Amplitude.instance().identify(identify)
    }
    
    func setUser(_ user: AnalyticsProviderUser?) {
        guard let id = user?.id else { return }
        Amplitude.instance().setUserId(id)
    }
}
