import Combine
import KeyAppKitCore
import BankTransfer

final class ChooseSourceOfFundsService: ChooseItemService {
    let chosenTitle = L10n.chosen
    let otherTitle = L10n.allSources
    let emptyTitle = L10n.notFound

    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>

    init() {
        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>(
            AsyncValueState(status: .ready, value: [ChooseItemListSection(items: StrigaSourceOfFunds.allCases)])
        )
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let isEmpty = items.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : items
    }

    func sortFiltered(by keyword: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}
