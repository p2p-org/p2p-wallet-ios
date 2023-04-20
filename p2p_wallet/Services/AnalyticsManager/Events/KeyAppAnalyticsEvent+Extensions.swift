import Foundation
import AnalyticsManager

extension KeyAppAnalyticsEvent {

    /// The name of the event to send
    var name: String? {
        // By default, name of the event will be converted from `camelCase` to `Uppercased_Snake_Case` format
        // For example: `KeyAppAnalyticsEvent.mainScreenSwapOpen` will be converted to "Main_Screen_Swap_Open" automatically.
        
        // Modify the name manually and prevent default behavior
        switch self {
        case .sellOnlySOLNotification:
            return "Sell_Only_SOL_Notification"
        case .swapChangingTokenAClick:
            return "Swap_Changing_Token_A_Click"
        case .swapChangingTokenBClick:
            return "Swap_Changing_Token_B_Click"
        case .swapErrorTokenAInsufficientAmount:
            return "Swap_Error_Token_A_Insufficient_Amount"
        case .swapChangingValueTokenAAll:
            return "Swap_Changing_Value_Token_A_All"
        default:
            break
        }
        
        // Default converter from `camelCase` to `Uppercased_Snake_Case` format
        return mirror.label.snakeAndFirstUppercased
    }

    /// Params sent with event
    var params: [String: Any]? {
        guard !mirror.params.isEmpty else { return nil }
        
        // The same for params, params key & value can be customized too, if not, it will be automatically converted to `Uppercased_Snake_Case`
        
        // Modify the key & value manually and prevent default behavior
        switch self {
        case let .swapChangingTokenAClick(tokenAName):
            return ["Token_A_Name": tokenAName]
        case let .swapChangingTokenBClick(tokenBName):
            return ["Token_B_Name": tokenBName]
        case let .swapChangingValueTokenA(tokenAName, tokenAValue):
            return ["Token_A_Name": tokenAName, "Token_A_Value": tokenAValue]
        case let .swapChangingValueTokenB(tokenBName, tokenBValue):
            return ["Token_B_Name": tokenBName, "Token_B_Value": tokenBValue]
        case let .swapChangingValueTokenAAll(tokenAName, tokenAValue):
            return ["Token_A_Name": tokenAName, "Token_A_Value": tokenAValue]
        case let .swapSwitchTokens(tokenAName, tokenBName):
            return ["Token_A_Name": tokenAName, "Token_B_Name": tokenBName]
        default:
            break
        }
        
        // Default converter from `camelCase` to `Uppercased_Snake_Case` format
        let formatted = mirror.params.map {
            var key = $0.key.snakeAndFirstUppercased
            
            switch key {
            case "Token_BName":
                key = "Token_B_Name"
            case "Token_BValue":
                key = "Token_B_Value"
            case "Token_AName":
                key = "Token_A_Name"
            case "Token_AValue":
                key = "Token_A_Value"
            default:
                break
            }
            
            return (key ?? "", $0.value)
        }
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
