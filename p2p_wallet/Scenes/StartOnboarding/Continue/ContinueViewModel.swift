import Combine
import SwiftUI
import UIKit

final class ContinueViewModel: BaseViewModel {
    @Published var data: StartPageData

    let continueDidTap = PassthroughSubject<Void, Never>()
    let startDidTap = PassthroughSubject<Void, Never>()

    override init() {
        data = OnboardingContentData(
            image: .safe,
            title: L10n.letSContinue,
            subtitle: L10n.YouHaveAGreatStartWith.itSOnlyAPhoneNumberNeededToCreateANewWallet("test@test.ru")
        )

        super.init()
    }
}
