import Combine
import SwiftUI
import UIKit

extension StartViewModel: ViewModelType {
    struct Input {
        let createWalletDidTap = PassthroughSubject<Void, Never>()
        let restoreWalletDidTap = PassthroughSubject<Void, Never>()
        let openTermsDidTap = PassthroughSubject<Void, Never>()
        var currentDataIndex = CurrentValueSubject<Int, Never>(.zero)
    }

    struct Output {
        let data = CurrentValueSubject<[StartPageData], Never>([])
    }

    enum NavigatableScene {
        case createWallet
        case restoreWallet
        case openTerms
    }

    struct Navigation {
        let action: AnyPublisher<NavigatableScene, Never>
    }
}

final class StartViewModel: BaseViewModel {
    var input: Input
    let output: Output
    let navigation: Navigation

    @Published private var data: [StartPageData] = []

    override init() {
        input = Input()
        output = Output()

        let action = Publishers.Merge3(
            input.createWalletDidTap.map { NavigatableScene.createWallet },
            input.restoreWalletDidTap.map { NavigatableScene.restoreWallet },
            input.openTermsDidTap.map { NavigatableScene.openTerms }
        )
        navigation = Navigation(action: action.eraseToAnyPublisher())

        super.init()

        bind()
        setData()
    }

    private func bind() {
        $data.sink { [weak self] value in
            self?.output.data.send(value)
        }.store(in: &subscriptions)
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
