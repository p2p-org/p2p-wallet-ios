import Combine
import CountriesAPI
import Foundation
import KeyAppKitCore
import Resolver

final class SelectRegionService: ChooseItemService {
    let chosenTitle = L10n.chosenCountry
    let otherTitle = L10n.allCountries
    let emptyTitle = L10n.nothingWasFound

    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> {
        statePublisher.eraseToAnyPublisher()
    }

    @Injected private var countriesService: CountriesAPI
    private let statePublisher: CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>

    init() {
        statePublisher = CurrentValueSubject<AsyncValueState<[ChooseItemListSection]>, Never>(
            AsyncValueState(status: .fetching, value: [])
        )

        Task {
            do {
                let countries = try await self.countriesService.fetchRegions()
                self.statePublisher.send(
                    AsyncValueState(status: .ready, value: [ChooseItemListSection(items: countries)])
                )
            } catch {
                DefaultLogManager.shared.log(event: "Error", logLevel: .error, data: error.localizedDescription)
                self.statePublisher.send(
                    AsyncValueState(status: .ready, value: [ChooseItemListSection(items: [])], error: error)
                )
            }
        }
    }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        let isEmpty = items.flatMap(\.items).isEmpty
        return isEmpty ? [] : items
    }

    func sortFiltered(by _: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}
