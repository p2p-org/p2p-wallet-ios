import Combine
import Resolver
import SolanaSwift
import Wormhole
import KeyAppKitCore
import KeyAppBusiness

final class ChooseWormholeTokenService: ChooseItemService {
    
    let otherTokensTitle = L10n.otherTokens

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
            return ChooseItemListSection(items: wallets.sorted())
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
        accountsService.$state
            .map({ state in
                state.apply { accounts in
                    [ChooseItemListSection(
                        items: accounts
                            .filter { SupportedToken.bridges.map(\.solAddress).contains($0.data.mintAddress) }
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
