import Combine
import SwiftUI
import UIKit

extension ContinueViewModel: ViewModelType {
    struct Input {
        let continueDidTap = PassthroughSubject<Void, Never>()
        let startDidTap = PassthroughSubject<Void, Never>()
    }

    enum NavigatableScene {
        case `continue`
        case start
    }

    struct Output {
        let navigateAction: AnyPublisher<NavigatableScene, Never>
    }
}

final class ContinueViewModel: BaseViewModel {
    @Published var data: StartPageData = .init(
        image: .safe,
        title: L10n.letSContinue,
        subtitle: L10n.YouHaveAGreatStartWith.itSOnlyAPhoneNumberNeededToCreateANewWallet("test@test.ru")
    )

    let input: Input
    let output: Output

    override init() {
        input = Input()

        let action = Publishers.Merge(
            input.continueDidTap.map { NavigatableScene.continue },
            input.startDidTap.map { NavigatableScene.start }
        )
        output = Output(navigateAction: action.eraseToAnyPublisher())

        super.init()
    }
}
