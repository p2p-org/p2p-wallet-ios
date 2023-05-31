import Combine
import Foundation
import KeyAppKitCore

final class ChooseIndustryService: ChooseItemService {
    let chosenTitle = L10n.chosen
    let otherTitle = L10n.allIndustries

    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>

    init(provider: ChooseIndustryDataProvider = ChooseIndustryDataLocalProvider()) {
        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>(
            AsyncValueState(status: .ready, value: [ChooseItemListSection(items: provider.getIndustries())])
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
