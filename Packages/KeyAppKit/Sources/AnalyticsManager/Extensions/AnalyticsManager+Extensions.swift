import AnalyticsManager
import Foundation

public extension AnalyticsManager {
    func log(event: KeyAppAnalyticsEvent) {
        log(event: event as AnalyticsEvent)
    }

    func log(parameter: KeyAppAnalyticsParameter) {
        log(parameter: parameter as AnalyticsParameter)
    }
}
