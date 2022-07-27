import Combine
import SwiftUI
import UIKit

extension StartViewModel: ViewModelType {
    struct Input {
        let createWalletDidTap = PassthroughSubject<Void, Never>()
        let restoreWalletDidTap = PassthroughSubject<Void, Never>()
        let openTermsDidTap = PassthroughSubject<Void, Never>()
    }

    enum NavigatableScene {
        case createWallet
        case restoreWallet
        case openTerms
    }

    struct Output {
        let navigateAction: AnyPublisher<NavigatableScene, Never>
    }
}

final class StartViewModel: BaseViewModel {
    @Published var data: [StartPageData] = [
        .init(
            image: .coins,
            title: L10n.welcomeToKeyApp,
            subtitle: L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos
        ),
        .init(
            image: .coins,
            title: "\(L10n.welcomeToKeyApp) 2",
            subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 2"
        ),
        .init(
            image: .coins,
            title: "\(L10n.welcomeToKeyApp) 3",
            subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 3"
        ),
        .init(
            image: .coins,
            title: "\(L10n.welcomeToKeyApp) 4",
            subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 4"
        ),
    ]

    @Published var currentIndex = 0

    let input: Input
    let output: Output

    override init() {
        input = Input()

        let action = Publishers.Merge3(
            input.createWalletDidTap.map { NavigatableScene.createWallet },
            input.restoreWalletDidTap.map { NavigatableScene.restoreWallet },
            input.openTermsDidTap.map { NavigatableScene.openTerms }
        )
        output = Output(navigateAction: action.eraseToAnyPublisher())

        super.init()
    }
}
