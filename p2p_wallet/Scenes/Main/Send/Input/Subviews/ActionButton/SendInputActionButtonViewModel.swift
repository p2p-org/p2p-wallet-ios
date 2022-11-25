import Combine

final class SendInputActionButtonViewModel: ObservableObject {
    struct ActionButton {
        let isEnabled: Bool
        let title: String
    }

    @Published var isSliderOn = false
    @Published var actionButton = ActionButton(isEnabled: true, title: L10n.enterTheAmount)
    @Published var showFinished = false
}
