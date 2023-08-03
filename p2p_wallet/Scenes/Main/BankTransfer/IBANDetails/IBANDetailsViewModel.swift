import BankTransfer
import Combine
import KeyAppUI
import Resolver
import SwiftUI
import SwiftyUserDefaults

final class IBANDetailsViewModel: BaseViewModel, ObservableObject {
    @Injected private var notificationService: NotificationService

    @Published var items: [any Renderable] = []
    let warningTapped = PassthroughSubject<Void, Never>()

    init(eurAccount: EURUserAccount) {
        super.init()
        items = makeItems(from: eurAccount)
    }

    private func makeItems(from account: EURUserAccount) -> [any Renderable] {
        [
            IBANDetailsCellViewItem(title: L10n.iban, subtitle: account.iban?.formatIBAN() ?? "") { [weak self] in
                self?.copy(value: account.iban)
            },
            ListSpacerCellViewItem(height: 1.0, backgroundColor: Color(asset: Asset.Colors.rain), leadingPadding: 20.0),
            IBANDetailsCellViewItem(title: L10n.currency, subtitle: account.currency, copyAction: nil),
            IBANDetailsCellViewItem(title: L10n.bic, subtitle: account.bic ?? "") { [weak self] in
                self?.copy(value: account.bic)
            },
            IBANDetailsCellViewItem(title: L10n.beneficiary,
                                    subtitle: account.bankAccountHolderName ?? "")
            { [weak self] in
                self?.copy(value: account.bankAccountHolderName)
            },
        ]
    }

    private func copy(value: String?) {
        UIPasteboard.general.string = value
        notificationService.showToast(title: "✅", text: L10n.copied)
    }
}
