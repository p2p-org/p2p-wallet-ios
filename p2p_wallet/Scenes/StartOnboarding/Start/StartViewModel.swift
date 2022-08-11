import Combine
import SwiftUI
import UIKit

final class StartViewModel: BaseViewModel {
    @Published var data: [StartPageData] = []
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
    }

    private func setData() {
        data = [
            OnboardingContentData(
                image: .coins,
                title: L10n.welcomeToKeyApp,
                subtitle: L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos
            ),
            OnboardingContentData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 2",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 2"
            ),
            OnboardingContentData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 3",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 3"
            ),
            OnboardingContentData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 4",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 4"
            ),
        ]
    }
}
