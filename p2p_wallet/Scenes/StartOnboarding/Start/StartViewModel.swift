import Combine
import SwiftUI
import UIKit

extension StartViewModel {
    enum NavigatableScene {
        case createWallet
        case restoreWallet
        case openTerms
        case mockContinue // TODO: Remove mock scene
    }
}

final class StartViewModel: BaseViewModel {
    @Published var data: [OnboardingContentData] = []
    @Published var navigatableScene: NavigatableScene?
    @Published var currentDataIndex: Int = .zero
    let isAnimatable: Bool

    let termsDidTap = PassthroughSubject<Void, Never>()
    let createWalletDidTap = PassthroughSubject<Void, Never>()
    let restoreWalletDidTap = PassthroughSubject<Void, Never>()
    let mockButtonDidTap = PassthroughSubject<Void, Never>()

    init(isAnimatable: Bool) {
        self.isAnimatable = isAnimatable
        super.init()

        Publishers.Merge4(
            createWalletDidTap.map { NavigatableScene.createWallet },
            restoreWalletDidTap.map { NavigatableScene.restoreWallet },
            termsDidTap.map { NavigatableScene.openTerms },
            mockButtonDidTap.map { NavigatableScene.mockContinue }
        ).sink { [weak self] scene in
            self?.navigatableScene = scene
        }.store(in: &subscriptions)

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
