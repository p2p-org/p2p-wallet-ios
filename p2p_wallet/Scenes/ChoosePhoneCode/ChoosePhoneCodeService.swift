import Combine
import CountriesAPI
import KeyAppKitCore
import Resolver

final class ChoosePhoneCodeService: ChooseItemService {
    let chosenTitle = L10n.selected
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
                let countries = try await self.countriesService.fetchCountries().unique
                    .map { PhoneCodeItem(country: $0) }
                let uniqueCountries = Array(Set(countries))
                self.statePublisher.send(
                    AsyncValueState(status: .ready, value: [ChooseItemListSection(items: uniqueCountries)])
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
        let newItems = items.map { section in
            guard let countries = section.items as? [PhoneCodeItem] else { return section }
            return ChooseItemListSection(items: countries
                .sorted(by: { $0.country.name.lowercased() < $1.country.name.lowercased() }))
        }
        let isEmpty = newItems.flatMap(\.items).isEmpty
        return isEmpty ? [] : newItems
    }

    func sortFiltered(by _: String, items: [ChooseItemListSection]) -> [ChooseItemListSection] {
        sort(items: items)
    }
}
