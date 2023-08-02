import Foundation
import XCTest
@testable import AnalyticsManager

class ProvidersTests: XCTestCase {
    func testKeyAppAnalytics_GiveDefaultEvents_ShouldReturnAmplitudeProviderId() {
        // Test case for events with only the default provider (Amplitude)
        let eventsWithDefaultProvider: [KeyAppAnalyticsEvent] = [
            .createPhoneClickButton,
            .restorePhoneClickButton,
        ]
        let defaultProviderIds: Set<String> = [KeyAppAnalyticsProviderId.amplitude.rawValue]
        let defaultProviderIdsResult = eventsWithDefaultProvider.flatMap(\.providerIds)
        XCTAssertEqual(Set(defaultProviderIdsResult), defaultProviderIds)
    }

    func testKeyAppAnalytics_GiveSpecialEvents_ShouldReturnAdditionalProviderIds() {
        // Test case for events with additional providers (AppsFlyer and Firebase Analytics)
        let eventsWithAdditionalProviders: [KeyAppAnalyticsEvent] = [
            .onboardingStartButton,
            .creationPhoneScreen,
            .createSmsValidation(result: true),
            .createConfirmPin(result: true),
            .usernameCreationScreen,
            .usernameCreationButton(result: true),
            .restoreSeed,
            .onboardingMerged,
            .login,
            .buyButtonPressed(
                sumCurrency: "",
                sumCoin: "",
                currency: "",
                coin: "",
                paymentMethod: "",
                bankTransfer: true,
                typeBankTransfer: ""
            ),
            .sendNewConfirmButtonClick(
                sendFlow: "",
                token: "",
                max: true,
                amountToken: 0,
                amountUSD: 0,
                fee: true,
                fiatInput: true,
                signature: "",
                pubKey: ""
            ),
            .swapClickApproveButton,
        ]
        let additionalProviderIds: Set<String> = [
            KeyAppAnalyticsProviderId.amplitude.rawValue,
            KeyAppAnalyticsProviderId.appsFlyer.rawValue,
            KeyAppAnalyticsProviderId.firebaseAnalytics.rawValue,
        ]
        let additionalProviderIdsResult = eventsWithAdditionalProviders.flatMap(\.providerIds)
        XCTAssertEqual(Set(additionalProviderIdsResult), additionalProviderIds)
    }
}
