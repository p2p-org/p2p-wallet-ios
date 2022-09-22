import Combine
import SwiftUI
import UIKit

final class ContinueViewModel: BaseViewModel {
    @Published var data: OnboardingContentData

    let continueDidTap = PassthroughSubject<Void, Never>()
    let startDidTap = PassthroughSubject<Void, Never>()

    init(subtitle: String) {
        data = OnboardingContentData(
            image: .emailLetsContinue,
            title: L10n.letSContinue,
            subtitle: subtitle
        )

        super.init()
    }
}
