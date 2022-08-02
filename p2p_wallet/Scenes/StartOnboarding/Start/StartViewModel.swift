import Combine
import SwiftUI
import UIKit

extension StartViewModel {
    enum NavigatableScene {
        case createWallet
        case restoreWallet
        case mockContinue // TODO: Remove mock scene
    }
}

final class StartViewModel: BaseViewModel {
    @Published var data: [StartPageData] = []
    @Published var navigatableScene: NavigatableScene?
    @Published var currentDataIndex: Int = .zero

    let createWalletDidTap = PassthroughSubject<Void, Never>()
    let restoreWalletDidTap = PassthroughSubject<Void, Never>()
    let mockButtonDidTap = PassthroughSubject<Void, Never>()

    override init() {
        super.init()

        Publishers.Merge3(
            createWalletDidTap.map { NavigatableScene.createWallet },
            restoreWalletDidTap.map { NavigatableScene.restoreWallet },
            mockButtonDidTap.map { NavigatableScene.mockContinue }
        ).sink { [weak self] scene in
            self?.navigatableScene = scene
        }.store(in: &subscriptions)

        setData()
    }

    private func setData() {
        data = [
            StartPageData(
                image: .coins,
                title: L10n.welcomeToKeyApp,
                subtitle: L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos
            ),
            StartPageData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 2",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 2"
            ),
            StartPageData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 3",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 3"
            ),
            StartPageData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 4",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 4"
            ),
        ]
    }
}
