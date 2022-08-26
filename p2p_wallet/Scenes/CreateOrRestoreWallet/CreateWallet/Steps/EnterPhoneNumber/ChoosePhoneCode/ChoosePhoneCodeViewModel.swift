//
//  ChoosePhoneCodeViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 21/07/2022.
//

import BECollectionView_Combine
import Combine
import CountriesAPI
import Foundation

final class ChoosePhoneCodeViewModel: BECollectionViewModel<SelectableCountry> {
    // MARK: - Dependencies

    // MARK: - Properties

    private var subscriptions = [AnyCancellable]()
    private var cachedResult = [SelectableCountry]()
    private var initialCountryCode: String?

    @Published var selectedCountryCode: String?
    @Published var keyword = ""
    let didClose = PassthroughSubject<Void, Never>()

    // MARK: - Initializers

    init(selectedCountryCode: String?) {
        initialCountryCode = selectedCountryCode
        super.init()
        $keyword
            .sink { [weak self] keyword in
                guard let self = self else { return }
                if keyword.isEmpty {
                    self.overrideData(by: self.placeInitialIfNeeded(countries: self.cachedResult))
                    return
                }
                var newData = self.cachedResult.filteredAndSorted(byKeyword: keyword)
                if newData.isEmpty {
                    newData.append(self.emptyCountryModel())
                } else {
                    newData = self.placeInitialIfNeeded(countries: newData)
                }
                self.overrideData(by: newData)
            }
            .store(in: &subscriptions)

        $selectedCountryCode.sink { [weak self] value in
            guard let value = value else { return }

            if let index = self?.cachedResult.firstIndex(where: {
                $0.value.code == self?.initialCountryCode
            }) {
                self?.cachedResult[index].isSelected = false
            }
            self?.initialCountryCode = nil

            if let index = self?.cachedResult.firstIndex(where: {
                $0.value.code == value.value
            }) {
                self?.cachedResult[index].isSelected = true
            }
        }
        .store(in: &subscriptions)
    }

    // MARK: - Methods

    override func createRequest() async throws -> [SelectableCountry] {
        let selectedCode = selectedCountryCode?.value ?? initialCountryCode
        cachedResult = try await CountriesAPIImpl().fetchCountries()
            .map { .init(value: $0, isSelected: $0.code == selectedCode) }
        var countries = cachedResult.filteredAndSorted(byKeyword: keyword.value)
        countries = placeInitialIfNeeded(countries: countries)
        return countries
    }

    private func emptyCountryModel() -> SelectableCountry {
        SelectableCountry(
            value: Country(name: L10n.sorryWeDonTKnowASuchCountry, dialCode: "", code: "", emoji: "🏴"),
            isSelected: false,
            isEmpty: true
        )
    }

    private func placeInitialIfNeeded(countries: [SelectableCountry]) -> [SelectableCountry] {
        guard initialCountryCode != nil else { return countries }
        var countries = countries
        // Put initial selected country in the first place
        if let selectedIndex = countries.firstIndex(where: { $0.value.code == initialCountryCode }) {
            let selectedCountry = countries.remove(at: selectedIndex)
            countries.insert(selectedCountry, at: .zero)
        }
        return countries
    }
}
