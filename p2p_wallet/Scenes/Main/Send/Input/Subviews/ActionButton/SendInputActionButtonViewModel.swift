import Combine

final class SendInputActionButtonViewModel: ObservableObject {
    struct ActionButton {
        let isEnabled: Bool
        let title: String

        static let zero = ActionButton(isEnabled: false, title: L10n.enterTheAmount)
    }

    @Published var isSliderOn = false
    @Published var actionButton = ActionButton.zero
    @Published var showFinished = false
}
