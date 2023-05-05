import Foundation

/// Event that can be sent via AnalyticsManager
public protocol AnalyticsEvent {
    /// The name of the event
    var name: String? { get }
    /// Params sent with event
    var params: [String: Any]? { get }
    /// Array of sending providers, even will be sent to only these defined providers
    var providerIds: [AnalyticsProviderId] { get }
}
