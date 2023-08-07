import BankTransfer
import Combine
import KeyAppUI
import Resolver
import SwiftUI
import SwiftyUserDefaults

final class BankTransferInfoViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var helpLauncher: HelpCenterLauncher
    @Injected private var notificationService: NotificationService

    // MARK: - Properties

    @Published var items: [any Renderable] = []
    @Published var isLoading = false

    // MARK: - Actions

    let openHelp = PassthroughSubject<Void, Never>()
    let openRegistration = PassthroughSubject<Void, Never>()
    let openBrowser = PassthroughSubject<URL, Never>()

    let requestContinue = PassthroughSubject<Void, Never>()
    let requestOpenTerms = PassthroughSubject<Void, Never>()
    let requestOpenPrivacyPolicy = PassthroughSubject<Void, Never>()

    override init() {
        super.init()
        bind()
        items = makeItems()
    }

    private func bind() {
        openHelp
            .sink { [weak self] in self?.helpLauncher.launch() }
            .store(in: &subscriptions)

        requestContinue
            .sinkAsync { [weak self] in
                self?.isLoading = true
                try? await Task.sleep(seconds: 3)
                self?.openRegistration.send(())
                self?.isLoading = false
            }
            .store(in: &subscriptions)

        requestOpenPrivacyPolicy
            .sink { [weak self] in
                self?.notificationService.showToast(title: "👹", text: "No URL YET")
//                self?.openBrowser.send(URL(string: "")) //TODO: Add URL
            }
            .store(in: &subscriptions)

        requestOpenTerms
            .sink { [weak self] in
                self?.notificationService.showToast(title: "👹", text: "No URL YET")
//                self?.openBrowser.send(URL(string: "")) //TODO: Add URL
            }
            .store(in: &subscriptions)
    }

    private func makeItems() -> [any Renderable] {
        [
            BankTransferInfoImageCellViewItem(image: .walletFound),
            ListSpacerCellViewItem(height: 16, backgroundColor: .clear),
            BankTransferTitleCellViewItem(title: L10n.openAccountForInstantInternationalTransfers),
            ListSpacerCellViewItem(height: 12, backgroundColor: .clear),
            CenterTextCellViewItem(
                text: L10n
                    .thisAccountActsAsAnIntermediaryBetweenKeyAppAndOurBankingPartnerStrigaPaymentProviderWhichOperatesWithYourFiatMoney,
                style: .text3,
                color: Asset.Colors.night.color
            ),
        ]
    }
}
