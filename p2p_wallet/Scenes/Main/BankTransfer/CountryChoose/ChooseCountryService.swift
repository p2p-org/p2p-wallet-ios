import Combine
import CountriesAPI
import Foundation
import KeyAppKitCore

final class ChooseCountryService: ChooseItemService {
    let chosenTitle = L10n.chosenCountry
    let otherTitle = L10n.allCountries

    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>

    init(countries: [Country]) {
        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>(
            AsyncValueState(status: .ready, value: [ChooseItemListSection(items: countries)])
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
