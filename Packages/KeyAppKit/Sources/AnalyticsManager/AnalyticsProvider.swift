import Foundation

public typealias AnalyticsProviderId = String

public protocol AnalyticsProvider {
    var providerId: AnalyticsProviderId { get }
    func logEvent(_ event: AnalyticsEvent)
    func logParameter(_ parameter: AnalyticsParameter)
    func setUser(_ user: AnalyticsProviderUser?)
}

public struct AnalyticsProviderUser {
    public let id: String?
    public let name: String?
    
    public init(
        id: String? = nil,
        name: String? = nil
    ) {
        self.id = id
        self.name = name
    }
}
