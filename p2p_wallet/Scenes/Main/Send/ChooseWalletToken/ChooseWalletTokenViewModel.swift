import Combine
import Resolver
import SolanaSwift

final class ChooseWalletTokenViewModel: BaseViewModel, ObservableObject {

    @Injected private var walletsRepository: WalletsRepository
    @Injected private var notifications: NotificationService

    let chooseTokenSubject = PassthroughSubject<Wallet, Never>()
    let close = PassthroughSubject<Void, Never>()
    let clearSearch = PassthroughSubject<Void, Never>()

    @Published var wallets: [Wallet] = []
    @Published var searchText: String = ""
    @Published var isSearchFieldFocused: Bool = true
    @Published var isSearchGoing: Bool = false
    @Published var title: String = ""
    @Published var isLoading: Bool = true

    let chosenToken: Wallet

    private let service: ChooseWalletTokenService

    private var allWallets: [Wallet] = []

    init(strategy: ChooseWalletTokenStrategy, chosenToken: Wallet) {
        self.chosenToken = chosenToken
        self.service = ChooseWalletTokenServiceImpl(strategy: strategy)
        super.init()
        self.title = configureTitle(strategy: strategy)

        Task {
            self.isLoading = true
            do {
                self.allWallets = try await service.getWallets()
                self.wallets = allWallets.filter({ $0.token.address != chosenToken.token.address })
                self.isLoading = false
            }
            catch let error {
                self.isLoading = false
                self.notifications.showDefaultErrorNotification()
            }
        }

        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                self.isSearchGoing = !value.isEmpty
                if value.isEmpty {
                    self.wallets = self.allWallets.filter({ $0.token.address != chosenToken.token.address })
                } else {
                    self.wallets = self.allWallets.filter({ $0.hasKeyword(value) })
                }
            }
            .store(in: &subscriptions)

        clearSearch
            .sink { [weak self] in
                self?.searchText = ""
            }
            .store(in: &subscriptions)
    }
}

private extension ChooseWalletTokenViewModel {
    func configureTitle(strategy: ChooseWalletTokenStrategy) -> String {
        switch strategy {
        case .feeToken:
            return L10n.PayThe0._03FeeWith
        case .sendToken:
            return L10n.pickAToken
        }
    }
}

private extension Wallet {
    func hasKeyword(_ keyword: String) -> Bool {
        token.symbol.lowercased().hasPrefix(keyword.lowercased()) ||
            token.symbol.lowercased().contains(keyword.lowercased()) ||
            token.name.lowercased().hasPrefix(keyword.lowercased()) ||
            token.name.lowercased().contains(keyword.lowercased())
    }
}
