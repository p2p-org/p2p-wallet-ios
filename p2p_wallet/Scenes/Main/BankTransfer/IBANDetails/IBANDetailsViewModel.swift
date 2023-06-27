import Combine
import Resolver
import KeyAppUI
import SwiftUI
import BankTransfer

final class IBANDetailsViewModel: BaseViewModel, ObservableObject {

    @Injected private var notificationService: NotificationService
    @Injected private var bankTransferService: BankTransferService

    @Published var items: [any Renderable] = []
    let learnMore = PassthroughSubject<Void, Never>()

    override init() {
        super.init()

        // TODO: Temprorary solution before local state is done. allWallets and enrichAccount eur should not be called here
        Task {
            do {
                let allWallets = try await bankTransferService.getAllWalletsByUser()

                if let eurId = allWallets.eur?.accountID {
                    let eurAccount: StrigaEnrichedEURAccountResponse = try await bankTransferService.enrichAccount(accountId: eurId)
                    self.items = makeItems(from: eurAccount)
                }

                if let usdcId = allWallets.usdc?.accountID {
                    enrichUSDCAccount(id: usdcId)
                }
            } catch {
                debugPrint(error)
            }
        }
    }

    private func makeItems(from account: StrigaEnrichedEURAccountResponse) -> [any Renderable] {
        return [
            IBANDetailsCellViewItem(title: L10n.iban, subtitle: account.iban) { [weak self] in
                self?.copy(value: account.iban)
            },
            ListSpacerCellViewItem(height: 1.0, backgroundColor: Color(asset: Asset.Colors.rain), leadingPadding: 20.0),
            IBANDetailsCellViewItem(title: L10n.currency, subtitle: account.currency, copyAction: nil),
            IBANDetailsCellViewItem(title: L10n.bic, subtitle: account.bic) { [weak self] in
                self?.copy(value: account.bic)
            },
            IBANDetailsCellViewItem(title: L10n.beneficiary, subtitle: account.bankAccountHolderName) { [weak self] in
                self?.copy(value: account.bankAccountHolderName)
            }
        ]
    }

    private func copy(value: String) {
        UIPasteboard.general.string = value
        notificationService.showToast(title: "✅", text: L10n.copied)
    }
}

private extension IBANDetailsViewModel {
    func enrichUSDCAccount(id: String) {
        Task {
            let _: StrigaEnrichedUSDCAccountResponse = try await bankTransferService.enrichAccount(accountId: id)
        }
    }
}
