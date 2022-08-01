import Combine
import SwiftUI
import UIKit

extension ContinueViewModel: ViewModelType {
    struct Input {
        let continueDidTap = PassthroughSubject<Void, Never>()
        let startDidTap = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let data = CurrentValueSubject<StartPageData, Never>(StartPageData.empty)
    }

    enum NavigatableScene {
        case `continue`
        case start
    }

    struct Navigation {
        let action: AnyPublisher<NavigatableScene, Never>
    }
}

final class ContinueViewModel: BaseViewModel {
    let input: Input
    let output: Output
    let navigation: Navigation

    @Published private var data = StartPageData.empty

    override init() {
        input = Input()
        output = Output()

        let action = Publishers.Merge(
            input.continueDidTap.map { NavigatableScene.continue },
            input.startDidTap.map { NavigatableScene.start }
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
        data = StartPageData(
            image: .safe,
            title: L10n.letSContinue,
            subtitle: L10n.YouHaveAGreatStartWith.itSOnlyAPhoneNumberNeededToCreateANewWallet("test@test.ru")
        )
    }
}

private extension StartPageData {
    static let empty = StartPageData(image: .coins, title: "", subtitle: "")
}
