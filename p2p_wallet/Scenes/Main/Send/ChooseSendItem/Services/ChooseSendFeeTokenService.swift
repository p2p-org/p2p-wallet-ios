import Combine
import KeyAppKitCore
import SolanaSwift

final class ChooseSendFeeTokenService: ChooseItemService {
    let otherTokensTitle = L10n.otherTokens

    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>

    init(tokens: [SolanaAccount]) {
        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>(
            AsyncValueState(status: .ready, value: [ChooseItemListSection(items: tokens)])
        )
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let newItems = items.map { section in
            guard let wallets = section.items as? [SolanaAccount] else { return section }
            return ChooseItemListSection(items: wallets
                .sorted(preferOrderSymbols: [TokenMetadata.usdc.symbol, TokenMetadata.usdt.symbol]))
        }
        let isEmpty = newItems.flatMap(\.items).isEmpty
        return isEmpty ? [] : newItems
    }

    func sortFiltered(by _: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}
