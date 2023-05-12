import Foundation
import AnalyticsManager
import Sentry

final class SentryAnalyticsProvider: AnalyticsProvider {

    // MARK: - Properties

    var providerId: AnalyticsProviderId {
        KeyAppAnalyticsProviderId.sentry.rawValue
    }
    
    // MARK: - Initializer

    init() {
        
    }
    
    // MARK: - Logging

    func logEvent(_ event: AnalyticsEvent) {
        
    }
    
    func logParameter(_ parameter: AnalyticsParameter) {
        
    }
    
    func setUser(_ user: AnalyticsProviderUser?) {
        guard let user, let userId = user.id else {
            SentrySDK.setUser(nil)
            return
        }
        var sentryUser = Sentry.User(userId: userId)
        sentryUser.username = user.name
        SentrySDK.setUser(sentryUser)
    }
}
