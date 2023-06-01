import Combine
import CountriesAPI
import Foundation
import KeyAppKitCore
import Resolver

final class ChooseCountryService: ChooseItemService {
    let chosenTitle = L10n.chosenCountry
    let otherTitle = L10n.allCountries
    let emptyTitle = L10n.notFound

    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    @Injected private var countriesService: CountriesAPI
    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>

    init() {
        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>(
            AsyncValueState(status: .ready, value: [])
        )

        Task {
            do {
                let countries = try await self.countriesService.fetchCountries().unique(keyPath: \.name)
                self.statePublisher.send(
                    AsyncValueState(status: .ready, value: [ChooseItemListSection(items: countries)])
                )
            } catch {
                DefaultLogManager.shared.log(error: error)
                self.statePublisher.send(
                    AsyncValueState(status: .ready, value: [ChooseItemListSection(items: [])], error: error)
                )
            }
        }
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let isEmpty = items.flatMap({ $0.items }).isEmpty
        return isEmpty ? [] : items
    }

    func sortFiltered(by keyword: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}
