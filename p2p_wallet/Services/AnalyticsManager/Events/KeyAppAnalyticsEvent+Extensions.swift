import Foundation
import AnalyticsManager

extension KeyAppAnalyticsEvent {

    /// The name of the event to send
    var name: String? {
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

    /// Array of sending providers, event will be sent to only these defined providers
    var providerIds: [AnalyticsProviderId] {
        // By default, all events will be sent to amplitude only
        var ids: [KeyAppAnalyticsProviderId] = [
            .amplitude
        ]
        
        // for some events, we will sent to appsFlyer and firebaseAnalytics
        switch self {
        case .onboardingStartButton,
                .creationPhoneScreen,
                .createSmsValidation,
                .createConfirmPin,
                .usernameCreationScreen,
                .usernameCreationButton,
                .restoreSeed,
                .onboardingMerged,
                .login,
                .buyButtonPressed,
                .sendNewConfirmButtonClick,
                .swapClickApproveButton:
            ids.append(contentsOf: [
                .appsFlyer,
                .firebaseAnalytics
            ])
        default:
            break
        }
        return ids.map(\.rawValue)
    }
    
    // MARK: - Helpers

    private var mirror: (label: String, params: [String: Any]) {
        let reflection = Mirror(reflecting: self)
        guard reflection.displayStyle == .enum,
              let associated = reflection.children.first
        else {
            return ("\(self)", [:])
        }
        let values = Mirror(reflecting: associated.value).children
        var valuesArray = [String: Any]()
        for case let item in values where item.label != nil {
            valuesArray[item.label!] = item.value
        }
        return (associated.label!, valuesArray)
    }
}
