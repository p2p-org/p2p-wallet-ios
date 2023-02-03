import Foundation
import AnalyticsManager

extension KeyAppAnalyticsEvent: MirrorableEnum {

    /// The name of the event to send
    var eventName: String? {
        // By default, name of the event will be converted from `camelCase` to `Uppercased_Snake_Case` format
        // For example: `KeyAppAnalyticsEvent.mainScreenSwapOpen` will be converted to "Main_Screen_Swap_Open" automatically.
        // Example: modify the name manually and prevent default behavior
        // switch self {
        // case .login:
        //     return "UserLoggedIn"
        // default:
        //     break
        // }
        
        // Default converter from `camelCase` to `Uppercased_Snake_Case` format
        return mirror.label.snakeAndFirstUppercased
    }

    /// Params sent with event
    var params: [String: Any]? {
        guard !mirror.params.isEmpty else { return nil }
        
        // The same for params, params key & value can be customized too, if not, it will be automatically converted to `Uppercased_Snake_Case`
        
        // Example: modify the key & value manually and prevent default behavior if needed
        // switch self {
        // case let .login(userId: String):
        //     return ["Id": userId] // by default userId -> User_Id
        // default:
        //     break
        // }
        
        // Default converter from `camelCase` to `Uppercased_Snake_Case` format
        let formatted = mirror.params.map { ($0.key.snakeAndFirstUppercased ?? "", $0.value) }
        return Dictionary(uniqueKeysWithValues: formatted)
    }

    /// Array of sending providers, even will be sent to only these defined providers
    var providerIds: [AnalyticsProviderId] {
        let ids: [KeyAppAnalyticsProviderId] = [
            .amplitude,
//            .appsFlyer,
//            .firebaseAnalytics
        ]
        return ids.map(\.rawValue)
    }
}

extension String {
    var snakeAndFirstUppercased: String? {
        guard let snakeCase = snakeCased() else { return nil }
        return snakeCase.prefix(1).uppercased() + snakeCase.dropFirst()
    }
    
    func snakeCased() -> String? {
        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
            .uppercaseFirst
    }
}
