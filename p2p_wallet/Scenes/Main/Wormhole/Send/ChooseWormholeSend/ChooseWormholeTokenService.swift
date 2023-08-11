import Combine
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

final class ChooseWormholeTokenService: ChooseItemService {
    let otherTitle = L10n.chosenToken
    let chosenTitle = L10n.otherTokens
    let emptyTitle = L10n.TokenNotFound.tryAnotherOne

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
            return ChooseItemListSection(items: wallets.sorted(preferOrderSymbols: [TokenMetadata.usdcet.symbol]))
        }
        let isEmpty = newItems.flatMap(\.items).isEmpty
        return isEmpty ? [] : newItems
    }

    func sortFiltered(by _: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}

private extension ChooseWormholeTokenService {
    func bind() {
        accountsService
            .statePublisher
            .map { state in
                state.apply { accounts in
                    [
                        ChooseItemListSection(
                            items: accounts
                                .filter {
                                    WormholeSupportedTokens.bridges.map(\.solAddress).contains($0.mintAddress)
                                        && $0.lamports > 0
                                }
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
