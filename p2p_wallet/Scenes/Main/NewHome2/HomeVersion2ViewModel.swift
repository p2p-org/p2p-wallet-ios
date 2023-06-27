import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift

class HomeVersion2ViewModel: BaseViewModel, ObservableObject {
    enum Category {
        case cash
        case crypto
    }

    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var notificationsService: NotificationService
    @Injected private var accountStorage: AccountStorageType

    @Published var nameAccount: String = ""

    @Published var category: Category = .cash

    let actionSubject: PassthroughSubject<HomeNavigation, Never>

    init(actionSubject : PassthroughSubject<HomeNavigation, Never>) {
        self.actionSubject = actionSubject
        super.init()

        let solanaAccountsService: SolanaAccountsService = Resolver.resolve()
        let nameStorage: NameStorageType = Resolver.resolve()

        solanaAccountsService.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateAddressIfNeeded(nameStorage)
            }
            .store(in: &subscriptions)
    }

    init(nameAccount: String)
    {
        self.actionSubject = .init()
        super.init()
        self.nameAccount = nameAccount
    }

    func copyToClipboard() {
        let nameStorage: NameStorageType = Resolver.resolve()
        let solanaAccountsService: SolanaAccountsService = Resolver.resolve()

        clipboardManager
            .copyToClipboard(nameStorage.getName() ?? solanaAccountsService.state.value.nativeWallet?.data.pubkey ?? "")
        let text: String
        if nameStorage.getName() != nil {
            text = L10n.usernameWasCopiedToClipboard
        } else {
            text = L10n.addressWasCopiedToClipboard
        }
        notificationsService.showToast(title: "🖤", text: text, haptic: true)
        analyticsManager.log(event: .mainCopyAddress)
    }

    func updateAddressIfNeeded(_ nameStorage: NameStorageType) {
        if let name = nameStorage.getName(), !name.isEmpty {
            nameAccount = name
        } else if let address = accountStorage.account?.publicKey.base58EncodedString.shortAddress {
            nameAccount = address
        }
    }

    func addMoney() {
        actionSubject.send(HomeNavigation.buy)
    }

    func withdraw() {
        actionSubject.send(HomeNavigation.cashOut)
    }

    func send() {
        actionSubject.send(HomeNavigation.send)
    }

    func receive() {
        actionSubject.send(HomeNavigation.receive)
    }
}

private extension String {
    var shortAddress: String {
        "\(prefix(4))...\(suffix(4))"
    }
}
