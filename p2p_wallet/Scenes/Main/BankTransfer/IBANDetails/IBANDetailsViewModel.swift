import Combine
import Resolver
import KeyAppUI
import SwiftUI
import BankTransfer

final class IBANDetailsViewModel: BaseViewModel, ObservableObject {

    @Injected private var notificationService: NotificationService

    @Published var items: [any Renderable] = []
    let learnMore = PassthroughSubject<Void, Never>()

    init(eurAccount: UserEURAccount) {
        super.init()
        self.items = self.makeItems(from: eurAccount)
    }

    private func makeItems(from account: UserEURAccount) -> [any Renderable] {
        return [
            IBANDetailsCellViewItem(title: L10n.iban, subtitle: account.iban ?? "") { [weak self] in
                self?.copy(value: account.iban)
            },
            ListSpacerCellViewItem(height: 1.0, backgroundColor: Color(asset: Asset.Colors.rain), leadingPadding: 20.0),
            IBANDetailsCellViewItem(title: L10n.currency, subtitle: account.currency, copyAction: nil),
            IBANDetailsCellViewItem(title: L10n.bic, subtitle: account.bic ?? "") { [weak self] in
                self?.copy(value: account.bic)
            },
            IBANDetailsCellViewItem(title: L10n.beneficiary, subtitle: account.bankAccountHolderName ?? "") { [weak self] in
                self?.copy(value: account.bankAccountHolderName)
            }
        ]
    }

    private func copy(value: String?) {
        UIPasteboard.general.string = value
        notificationService.showToast(title: "✅", text: L10n.copied)
    }
}
