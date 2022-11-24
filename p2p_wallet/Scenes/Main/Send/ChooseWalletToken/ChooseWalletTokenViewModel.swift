import Combine
import Resolver
import SolanaSwift

final class ChooseWalletTokenViewModel: ObservableObject {

    @Injected private var walletsRepository: WalletsRepository

    let chooseTokenSubject = PassthroughSubject<Wallet, Never>() // TODO: Bind to coordinator
    let close = PassthroughSubject<Void, Never>() // TODO: Bind to coordinator
    let clearSearch = PassthroughSubject<Void, Never>()

    @Published var wallets: [Wallet] = []
    @Published var searchText: String = ""
    @Published var isSearchFieldFocused: Bool = true
    @Published var isSearchGoing: Bool = false

    let chosenToken: Wallet

    private var subscriptions = Set<AnyCancellable>()

    private var allWallets: [Wallet] {
        walletsRepository.getWallets()
    }

    init(chosenToken: Wallet) {
        self.chosenToken = chosenToken

        wallets = allWallets.filter({ $0.token.address != chosenToken.token.address })

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

private extension Wallet {
    func hasKeyword(_ keyword: String) -> Bool {
        token.symbol.lowercased().hasPrefix(keyword.lowercased()) ||
            token.symbol.lowercased().contains(keyword.lowercased()) ||
            token.name.lowercased().hasPrefix(keyword.lowercased()) ||
            token.name.lowercased().contains(keyword.lowercased())
    }
}
