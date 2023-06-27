import Foundation
import AnalyticsManager

enum KeyAppAnalyticsParameter: AnalyticsParameter {
    case userHasPositiveBalance(Bool)
    case userAggregateBalance(Double)

    // Onboarding
    case userRestoreMethod(String)
    case userDeviceshare(Bool)
    
    case pushAllowed(Bool)
}
