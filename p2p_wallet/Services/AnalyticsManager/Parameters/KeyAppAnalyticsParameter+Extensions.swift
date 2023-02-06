import Foundation
import AnalyticsManager

extension KeyAppAnalyticsParameter: MirrorableEnum {
    var name: String? {
        mirror.label.snakeAndFirstUppercased
    }

    var value: Any? {
        mirror.params.values.first
    }
    
    var providerIds: [AnalyticsProviderId] {
        [KeyAppAnalyticsProviderId.amplitude].map(\.rawValue)
    }
}
