import XCTest
@testable import AnalyticsManager

class EventsTest: XCTestCase {
    func testKeyAppAnalytics_NormalEventsNameAndParams_ShouldReturnStandardNameAndParams() throws {
        // Test case for createPhoneClickButton
        let createPhoneClickButtonEvent = KeyAppAnalyticsEvent.createPhoneClickButton
        XCTAssertEqual(createPhoneClickButtonEvent.name, "Create_Phone_Click_Button")
        XCTAssertNil(createPhoneClickButtonEvent.params)

        // Test case for restorePhoneClickButton
        let restorePhoneClickButtonEvent = KeyAppAnalyticsEvent.restorePhoneClickButton
        XCTAssertEqual(restorePhoneClickButtonEvent.name, "Restore_Phone_Click_Button")
        XCTAssertNil(restorePhoneClickButtonEvent.params)

        // Test case for restoreSmsValidation
        let result = true // Replace this with the actual result you want to test
        let restoreSmsValidationEvent = KeyAppAnalyticsEvent.restoreSmsValidation(result: result)
        XCTAssertEqual(restoreSmsValidationEvent.name, "Restore_Sms_Validation")
        XCTAssertEqual(restoreSmsValidationEvent.params?["Result"] as! Bool, result)

        // Test cases for Setup events
        let fromPage = "ExamplePage" // Replace this with the actual fromPage value you want to test for setupOpen
        let setupOpenEvent = KeyAppAnalyticsEvent.setupOpen(fromPage: fromPage)
        XCTAssertEqual(setupOpenEvent.name, "Setup_Open")
        XCTAssertEqual(setupOpenEvent.params?["From_Page"] as! String, fromPage)

        let path =
            "ExamplePath" // Replace this with the actual path value you want to test for
        // recoveryDerivableAccountsPathSelected
        let recoveryDerivableAccountsPathSelectedEvent = KeyAppAnalyticsEvent
            .recoveryDerivableAccountsPathSelected(path: path)
        XCTAssertEqual(recoveryDerivableAccountsPathSelectedEvent.name, "Recovery_Derivable_Accounts_Path_Selected")
        XCTAssertEqual(recoveryDerivableAccountsPathSelectedEvent.params?["Path"] as! String, path)

        let recoveryRestoreClickEvent = KeyAppAnalyticsEvent.recoveryRestoreClick
        XCTAssertEqual(recoveryRestoreClickEvent.name, "Recovery_Restore_Click")
        XCTAssertNil(recoveryRestoreClickEvent.params)

        let recoveryDerivableAccountsOpenEvent = KeyAppAnalyticsEvent.recoveryDerivableAccountsOpen
        XCTAssertEqual(recoveryDerivableAccountsOpenEvent.name, "Recovery_Derivable_Accounts_Open")
        XCTAssertNil(recoveryDerivableAccountsOpenEvent.params)

        // Test cases for Main section - User Balance
        let amountUsd =
            100.0 // Replace this with the actual amount in USD you want to test for userAggregateBalanceBase
        let currency = "USD" // Replace this with the actual currency you want to test for userAggregateBalanceBase
        let userAggregateBalanceBaseEvent = KeyAppAnalyticsEvent.userAggregateBalanceBase(
            amountUsd: amountUsd,
            currency: currency
        )
        XCTAssertEqual(userAggregateBalanceBaseEvent.name, "User_Aggregate_Balance_Base")
        XCTAssertEqual(userAggregateBalanceBaseEvent.params?["Amount_Usd"] as! Double, amountUsd)
        XCTAssertEqual(userAggregateBalanceBaseEvent.params?["Currency"] as! String, currency)
    }

    func testKeyAppAnalytics_SpecialEventsNameAndParams_ShouldReturnModifiedNameAndParams() throws {
        // Test cases for Swap events
        let sellOnlySOLNotificationEvent = KeyAppAnalyticsEvent.sellOnlySOLNotification
        XCTAssertEqual(sellOnlySOLNotificationEvent.name, "Sell_Only_SOL_Notification")
        XCTAssertNil(sellOnlySOLNotificationEvent.params)

        let tokenAName =
            "TokenA" // Replace this with the actual token A name you want to test for swapChangingTokenAClick
        let swapChangingTokenAClickEvent = KeyAppAnalyticsEvent.swapChangingTokenAClick(tokenAName: tokenAName)
        XCTAssertEqual(swapChangingTokenAClickEvent.name, "Swap_Changing_Token_A_Click")
        XCTAssertEqual(swapChangingTokenAClickEvent.params?["Token_A_Name"] as! String, tokenAName)

        let tokenBName =
            "TokenB" // Replace this with the actual token B name you want to test for swapChangingTokenBClick
        let swapChangingTokenBClickEvent = KeyAppAnalyticsEvent.swapChangingTokenBClick(tokenBName: tokenBName)
        XCTAssertEqual(swapChangingTokenBClickEvent.name, "Swap_Changing_Token_B_Click")
        XCTAssertEqual(swapChangingTokenBClickEvent.params?["Token_B_Name"] as! String, tokenBName)

        let swapErrorTokenAInsufficientAmountEvent = KeyAppAnalyticsEvent.swapErrorTokenAInsufficientAmount
        XCTAssertEqual(swapErrorTokenAInsufficientAmountEvent.name, "Swap_Error_Token_A_Insufficient_Amount")
        XCTAssertNil(swapErrorTokenAInsufficientAmountEvent.params)

        let swapChangingValueTokenAAllEvent = KeyAppAnalyticsEvent.swapChangingValueTokenAAll(
            tokenAName: tokenAName,
            tokenAValue: 100.0
        )
        XCTAssertEqual(swapChangingValueTokenAAllEvent.name, "Swap_Changing_Value_Token_A_All")
        XCTAssertEqual(swapChangingValueTokenAAllEvent.params?["Token_A_Name"] as! String, tokenAName)
        XCTAssertEqual(swapChangingValueTokenAAllEvent.params?["Token_A_Value"] as! Double, 100.0)

        let swapChangingValueTokenAEvent = KeyAppAnalyticsEvent.swapChangingValueTokenA(
            tokenAName: tokenAName,
            tokenAValue: 50.0
        )
        XCTAssertEqual(swapChangingValueTokenAEvent.name, "Swap_Changing_Value_Token_A")
        XCTAssertEqual(swapChangingValueTokenAEvent.params?["Token_A_Name"] as! String, tokenAName)
        XCTAssertEqual(swapChangingValueTokenAEvent.params?["Token_A_Value"] as! Double, 50.0)

        let swapChangingValueTokenBEvent = KeyAppAnalyticsEvent.swapChangingValueTokenB(
            tokenBName: tokenBName,
            tokenBValue: 200.0,
            transactionSimulation: true
        )
        XCTAssertEqual(swapChangingValueTokenBEvent.name, "Swap_Changing_Value_Token_B")
        XCTAssertEqual(swapChangingValueTokenBEvent.params?["Token_B_Name"] as! String, tokenBName)
        XCTAssertEqual(swapChangingValueTokenBEvent.params?["Token_B_Value"] as! Double, 200.0)
        XCTAssertEqual(swapChangingValueTokenBEvent.params?["Transaction_Simulation"] as! Bool, true)

        let swapSwitchTokensEvent = KeyAppAnalyticsEvent.swapSwitchTokens(
            tokenAName: tokenAName,
            tokenBName: tokenBName
        )
        XCTAssertEqual(swapSwitchTokensEvent.name, "Swap_Switch_Tokens")
        XCTAssertEqual(swapSwitchTokensEvent.params?["Token_A_Name"] as! String, tokenAName)
        XCTAssertEqual(swapSwitchTokensEvent.params?["Token_B_Name"] as! String, tokenBName)

        // ... Test cases for User Balance and other remaining events (if applicable) ...
    }
}
