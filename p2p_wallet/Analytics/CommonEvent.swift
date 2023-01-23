//
//  CommonEvent.swift
//  p2p_wallet
//
//  Created by Ivan on 12.12.2022.
//

import Foundation

extension NewAnalyticsEvent {
    static let onboardingStartButton = NewAnalyticsEvent(name: "Onboarding_Start_Button")
    static let creationPhoneScreen = NewAnalyticsEvent(name: "Creation_Phone_Screen")
    static func createSmsValidation(result: Bool) -> NewAnalyticsEvent {
        NewAnalyticsEvent(name: "Create_Sms_Validation", parameters: ["Result": result])
    }
    static func createConfirmPin(result: Bool) -> NewAnalyticsEvent {
        NewAnalyticsEvent(name: "Create_Confirm_Pin", parameters: ["Result": result])
    }
    static let usernameCreationScreen = NewAnalyticsEvent(name: "Username_Creation_Screen")
    static func usernameCreationButton(result: Bool) -> NewAnalyticsEvent {
        NewAnalyticsEvent(name: "Username_Creation_Button", parameters: ["Result": result])
    }
    static let restoreSeed = NewAnalyticsEvent(name: "Restore_Seed")
    static let onboardingMerged = NewAnalyticsEvent(name: "Onboarding_Merged")
    static let login = NewAnalyticsEvent(name: "Login")
    static func buyButtonPressed(
        sumCurrency: String,
        sumCoin: String,
        currency: String,
        coin: String,
        paymentMethod: String,
        bankTransfer: Bool,
        typeBankTransfer: String?
    ) -> NewAnalyticsEvent {
        NewAnalyticsEvent(name: "Buy_Button_Pressed", parameters: [
            "Sum_Currency": sumCurrency,
            "Sum_Coin": sumCoin,
            "Currency": currency,
            "Coin": coin,
            "Payment_Method": paymentMethod,
            "Bank_Transfer": bankTransfer,
            "Type_Bank_Transfer": typeBankTransfer
        ])
    }
    static func sendNewConfirmButtonClick(
        source: String,
        token: String,
        max: Bool,
        amountToken: Double,
        amountUSD: Double,
        fee: Bool,
        fiatInput: Bool
    ) -> NewAnalyticsEvent {
        NewAnalyticsEvent(name: "Sendnew_Confirm_Button_Click", parameters: [
            "Source": source,
            "Token": token,
            "MAX": max,
            "Amount_Token": amountToken,
            "Amount_USD": amountUSD,
            "Fee": fee,
            "Fiat_Input": fiatInput
        ])
    }
    static let swapClickApproveButton = NewAnalyticsEvent(name: "Swap_Click_Approve_Button")
}
