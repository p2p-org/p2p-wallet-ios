import SolanaSwift
import Resolver
import Combine
import KeyAppKitCore
import KeyAppBusiness

final class ChooseSendTokenService: ChooseItemService {
    let chosenTitle = L10n.chosenToken
    let otherTitle = L10n.otherTokens

    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>
    @Injected private var accountsService: SolanaAccountsService
    private var subscriptions = [AnyCancellable]()

    init() {
        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>(AsyncValueState(value: []))
        bind()
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            guard let wallets = section.items as? [Wallet] else { return section }
            return ChooseItemListSection(items: wallets.sorted(preferOrderSymbols: [Token.usdc.symbol, Token.usdt.symbol]))
        }
        let isEmpty = newItems.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : newItems
    }

    func sortFiltered(by keyword: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}

private extension ChooseSendTokenService {
    func bind() {
        accountsService
            .statePublisher
            .map({ state in
                state.apply { accounts in
                    [ChooseItemListSection(
                        items: accounts
                            .filter { ($0.data.lamports ?? 0) > 0 && !$0.data.isNFTToken }
                            .map(\.data))
                    ]
                }
            })
            .sink { [weak self] state in
                self?.statePublisher.send(state)
            }
            .store(in: &subscriptions)
    }
}
