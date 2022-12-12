import AnalyticsManager
import Combine
import Resolver
import SwiftUI
import UIKit

final class StartViewModel: BaseViewModel, ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var analyticsService: AnalyticsService

    @Published var data: [OnboardingContentData] = []

    let isAnimatable: Bool
    let termsDidTap = PassthroughSubject<Void, Never>()
    let privacyPolicyDidTap = PassthroughSubject<Void, Never>()
    let createWalletDidTap = PassthroughSubject<Void, Never>()
    let restoreWalletDidTap = PassthroughSubject<Void, Never>()
    let mockButtonDidTap = PassthroughSubject<Void, Never>()

    init(isAnimatable: Bool) {
        self.isAnimatable = isAnimatable
        super.init()
        setData()

        createWalletDidTap
            .sink { [unowned self] in
                analyticsService.logEvent(.onboardingStartButton)
            }
            .store(in: &subscriptions)

        restoreWalletDidTap.sink { [unowned self] in
            self.analyticsManager.log(event: AmplitudeEvent.restoreWalletButton)
        }.store(in: &subscriptions)
    }

    private func setData() {
        data = [
            OnboardingContentData(
                image: .startOne,
                title: L10n.keyApp,
                subtitle: L10n.easyWayToEarnInvestAndSendCryptoWithZeroFees
            ),
            OnboardingContentData(
                image: .startTwo,
                title: L10n.neverLoseAccessToYourFunds,
                subtitle: L10n.OnlyYouHaveAccessToYourFunds.youCanRecoverYourWalletUsingYourPhoneOrEmail
            ),
            OnboardingContentData(
                image: .startThree,
                title: L10n.sendForFree,
                subtitle: L10n.usdcusdtbtcethsolAndOtherCryptocurrenciesWithLightspeedAndZeroFees
            ),
            OnboardingContentData(
                image: .startFour,
                title: L10n.buyOver150Currencies,
                subtitle: L10n.easySwapWithCreditCardOrBankTransfer
            )
        ]
    }
}
