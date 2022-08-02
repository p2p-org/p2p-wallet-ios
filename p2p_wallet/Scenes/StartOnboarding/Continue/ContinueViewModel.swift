import Combine
import SwiftUI
import UIKit

extension ContinueViewModel {
    enum NavigatableScene {
        case `continue`
        case start
    }
}

final class ContinueViewModel: BaseViewModel {
    @Published var data: StartPageData
    @Published var navigatableScene: NavigatableScene?

    let continueDidTap = PassthroughSubject<Void, Never>()
    let startDidTap = PassthroughSubject<Void, Never>()

    override init() {
        data = StartPageData(
            image: .safe,
            title: L10n.letSContinue,
            subtitle: L10n.YouHaveAGreatStartWith.itSOnlyAPhoneNumberNeededToCreateANewWallet("test@test.ru")
        )

        super.init()

        Publishers.Merge(
            continueDidTap.map { NavigatableScene.continue },
            startDidTap.map { NavigatableScene.start }
        ).sink { [weak self] value in
            self?.navigatableScene = value
        }.store(in: &subscriptions)
    }
}
