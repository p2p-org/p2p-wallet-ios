import Combine
import Resolver
import KeyAppUI
import SwiftUI

final class IBANDetailsViewModel: BaseViewModel, ObservableObject {

    @Injected private var notificationService: NotificationService

    @Published var items: [any Renderable] = []
    let learnMore = PassthroughSubject<Void, Never>()

    override init() {
        super.init()
        self.items = makeItems()
    }

    private func makeItems() -> [any Renderable] {
        return [
            IBANDetailsCellViewItem(title: L10n.iban, subtitle: "AD42 5634 6435 4324 5325") { [weak self] in
                self?.copy(value: "AD42 5634 6435 4324 5325")
            },
            ListSpacerCellViewItem(height: 1.0, backgroundColor: Color(asset: Asset.Colors.rain), leadingPadding: 20.0),
            IBANDetailsCellViewItem(title: L10n.currency, subtitle: "EUR", copyAction: nil),
            IBANDetailsCellViewItem(title: L10n.bic, subtitle: "CODEWORD") { [weak self] in
                self?.copy(value: "CODEWORD")
            },
            IBANDetailsCellViewItem(title: L10n.beneficiary, subtitle: "Name Surname") { [weak self] in
                self?.copy(value: "Name Surname")
            }
        ]
    }

    private func copy(value: String) {
        UIPasteboard.general.string = value
        notificationService.showToast(title: "✅", text: L10n.copied)
    }
}
