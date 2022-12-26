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
                self.wallets = allWallets.filter({ $0.token.address != chosenToken.token.address }).filteredAndSorted()
                self.isLoading = false
            }
            catch {
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
                    self.wallets = self.allWallets.filter({ $0.token.address != chosenToken.token.address }).filteredAndSorted()
                } else {
                    self.wallets = self.allWallets.filteredAndSorted(byKeyword: value)
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
        case let .feeToken(_, feeInFiat):
            return L10n.payTheFeeWith("~\(feeInFiat.fiatAmount(roundingMode: .down))")
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

private extension Array where Element == Wallet {
    func filteredAndSorted(byKeyword keyword: String = "") -> Self {
        var wallets = self

        if !keyword.isEmpty {
            let keyword = keyword.lowercased()
            wallets = wallets
                .filter { wallet in
                    // Filter only wallets which name starts with keyword
                    return wallet.token.name.lowercased().starts(with: keyword)
                    || wallet.token.name.lowercased().split(separator: " ").map { $0.starts(with: keyword) }.contains(true)
                }
        }

        let preferOrder: [String: Int] = ["USDC": 1, "USDT": 2]
        let sortedWallets = wallets
            .sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
                if preferOrder[lhs.token.symbol] != nil || preferOrder[rhs.token.symbol] != nil {
                    return (preferOrder[lhs.token.symbol] ?? 3) < (preferOrder[rhs.token.symbol] ?? 3)
                } else {
                    return lhs.amountInCurrentFiat > rhs.amountInCurrentFiat
                }
            }
        return sortedWallets
    }
}
