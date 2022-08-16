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
    private var initialSelectedCountry: Country?

    @Published var selectedCountry: SelectableCountry?
    @Published var keyword = ""
    let didClose = PassthroughSubject<Void, Never>()

    // MARK: - Initializers

    init(selectedCountry: Country? = nil) {
        initialSelectedCountry = selectedCountry
        super.init()
        $keyword
            .sink { [weak self] keyword in
                guard let self = self else { return }
                if keyword.isEmpty {
                    self.overrideData(by: self.cachedResult)
                    return
                }
                var newData = self.cachedResult.filteredAndSorted(byKeyword: keyword)
                if newData.isEmpty {
                    newData.append(self.emptyCountryModel())
                }
                self.overrideData(by: newData)
            }
            .store(in: &subscriptions)

        $selectedCountry.sink { [weak self] country in
            guard country != nil else { return }
            self?.initialSelectedCountry = nil
        }
        .store(in: &subscriptions)
    }

    // MARK: - Methods

    override func createRequest() async throws -> [SelectableCountry] {
        let selectedCode = selectedCountry?.value.code ?? initialSelectedCountry?.code
        cachedResult = try await CountriesAPIImpl().fetchCountries()
            .map { .init(value: $0, isSelected: $0.code == selectedCode) }
        var countries = cachedResult.filteredAndSorted(byKeyword: keyword.value)
        // Put initial selected country in the first place
        if let selectedIndex = countries.firstIndex(where: { $0.value.code == initialSelectedCountry?.code }) {
            let selectedCountry = countries.remove(at: selectedIndex)
            countries.insert(selectedCountry, at: .zero)
        }
        return countries
    }

    private func emptyCountryModel() -> SelectableCountry {
        SelectableCountry(
            value: Country(name: L10n.sorryWeDonTKnowASuchCountry, dialCode: "", code: "", emoji: "🏴"),
            isSelected: false,
            isEmpty: true
        )
    }
}
