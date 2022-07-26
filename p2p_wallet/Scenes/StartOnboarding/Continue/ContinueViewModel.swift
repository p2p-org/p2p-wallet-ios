import Combine
import SwiftUI
import UIKit

enum ContinueViewModelOut {
    case `continue`
    case start
}

final class ContinueViewModel: BaseViewModel {
    @Published var data: StartPageData = .init(
        image: .tokens,
        title: L10n.letSContinue,
        subtitle: L10n.YouHaveAGreatStartWith.itSOnlyAPhoneNumberNeededToCreateANewWallet("test@test.ru")
    )

    @Published var result: ContinueViewModelOut = .continue

    func continuePressed() {
        result = .continue
    }

    func startPressed() {
        result = .start
    }
}
