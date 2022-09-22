import Combine
import SwiftUI
import UIKit

final class StartViewModel: BaseViewModel {
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
    }

    private func setData() {
        data = [
            OnboardingContentData(
                image: .welcome,
                title: L10n.welcomeToKeyApp,
                subtitle: L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos
            ),
        ]
    }
}
