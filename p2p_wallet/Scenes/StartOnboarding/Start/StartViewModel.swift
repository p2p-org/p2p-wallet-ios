import AnalyticsManager
import Combine
import Resolver
import SwiftUI
import UIKit

final class StartViewModel: BaseViewModel {
    @Injected private var analyticsManager: AnalyticsManager

    @Published var data: [OnboardingContentData] = []
    @Published var currentDataIndex: Int = .zero

    let isAnimatable: Bool
    let termsDidTap = PassthroughSubject<Void, Never>()
    let createWalletDidTap = PassthroughSubject<Void, Never>()
    let restoreWalletDidTap = PassthroughSubject<Void, Never>()
    let mockButtonDidTap = PassthroughSubject<Void, Never>()

    init(isAnimatable: Bool) {
        self.isAnimatable = isAnimatable
        super.init()
        setData()

        createWalletDidTap.sink { [unowned self] in
            self.analyticsManager.log(event: AmplitudeEvent.onboardingStartButton)
        }.store(in: &subscriptions)

        restoreWalletDidTap.sink { [unowned self] in
            self.analyticsManager.log(event: AmplitudeEvent.restoreWalletButton)
        }.store(in: &subscriptions)
    }

    private func setData() {
        data = [
            OnboardingContentData(
                image: .welcome,
                title: L10n.welcomeToKeyApp,
                subtitle: L10n.easyWayToEarnInvestAndSendCryptoWithZeroFees
            ),
        ]
    }
}
