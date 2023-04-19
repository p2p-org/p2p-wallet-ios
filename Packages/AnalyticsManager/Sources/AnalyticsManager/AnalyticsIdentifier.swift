import Foundation

/// Parameter that can be sent via AnalyticsManager
public protocol AnalyticsParameter {
    /// The name of the event
    var name: String? { get }
    /// Params sent with event
    var value: Any? { get }
    /// Array of sending providers, even will be sent to only these defined providers
    var providerIds: [AnalyticsProviderId] { get }
}
