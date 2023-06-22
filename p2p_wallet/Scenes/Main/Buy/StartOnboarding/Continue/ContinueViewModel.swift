import Combine
import SwiftUI
import UIKit

final class ContinueViewModel: BaseViewModel, ObservableObject {
    @Published var data: OnboardingContentData

    let continueDidTap = PassthroughSubject<Void, Never>()
    let startDidTap = PassthroughSubject<Void, Never>()

    init(subtitle: String) {
        data = OnboardingContentData(
            image: UIImage(resource: .emailLetsContinue),
            title: L10n.letSContinue,
            subtitle: subtitle
        )

        super.init()
    }
}
