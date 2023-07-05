import Combine
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift

final class ChooseSendTokenService: ChooseItemService {
    let otherTokensTitle = L10n.otherTokens

    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>
    @Injected private var accountsService: SolanaAccountsService
    private var subscriptions = [AnyCancellable]()

    init() {
        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>,
            Never>(AsyncValueState(value: []))
        bind()
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            guard let wallets = section.items as? [SolanaAccount] else { return section }
            return ChooseItemListSection(items: wallets
                .sorted(preferOrderSymbols: [Token.usdc.symbol, Token.usdt.symbol]))
        }
        let isEmpty = newItems.flatMap(\.items).isEmpty
        return isEmpty ? [] : newItems
    }

    func sortFiltered(by _: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}

private extension ChooseSendTokenService {
    func bind() {
        accountsService
            .statePublisher
            .map { state in
                state.apply { accounts in
                    [
                        ChooseItemListSection(
                            items: accounts.filter { $0.lamports > 0 && !$0.isNFTToken }
                        ),
                    ]
                }
            }
            .sink { [weak self] state in
                self?.statePublisher.send(state)
            }
            .store(in: &subscriptions)
    }
}
