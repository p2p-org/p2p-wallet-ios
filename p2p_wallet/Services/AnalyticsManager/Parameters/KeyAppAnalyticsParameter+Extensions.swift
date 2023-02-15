import Foundation
import AnalyticsManager

extension KeyAppAnalyticsParameter {
    var name: String? {
        mirror.label.snakeAndFirstUppercased
    }

    var value: Any? {
        mirror.value
    }
    
    var providerIds: [AnalyticsProviderId] {
        [KeyAppAnalyticsProviderId.amplitude].map(\.rawValue)
    }
    
    // MARK: - Helpers

    private var mirror: (label: String, value: Any?) {
        let reflection = Mirror(reflecting: self)
        guard reflection.displayStyle == .enum,
              let associated = reflection.children.first,
              let label = associated.label
        else {
            return ("\(self)", nil)
        }
        return (label, associated.value)
    }
}
