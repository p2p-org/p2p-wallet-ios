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

extension ChoosePhoneCodeViewModel: ViewModelType {
    struct Input {
        let didClose = PassthroughSubject<Void, Never>()
        let keyword = CurrentValueSubject<String, Never>("")
    }

    struct Output {}
}

final class ChoosePhoneCodeViewModel: BECollectionViewModel<SelectableCountry> {
    // MARK: - Dependencies

    // MARK: - Properties

    private var subscriptions = [AnyCancellable]()
    private var cachedResult = [SelectableCountry]()
    private var initialSelectedCountry: Country?

    let input: Input
    let output: Output

    // MARK: - Initializers

    init(selectedCountry: Country? = nil) {
        initialSelectedCountry = selectedCountry
        input = Input()
        output = Output()
        super.init()
        input.keyword
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
    }

    // MARK: - Methods

    override func createRequest() async throws -> [SelectableCountry] {
        let initialSelectedCountry = initialSelectedCountry
        if self.initialSelectedCountry != nil {
            self.initialSelectedCountry = nil
        }
        cachedResult = try await CountriesAPIImpl().fetchCountries()
            .map { .init(value: $0, isSelected: $0.code == initialSelectedCountry?.code) }
        return cachedResult
            .filteredAndSorted(byKeyword: input.keyword.value)
    }

    private func emptyCountryModel() -> SelectableCountry {
        SelectableCountry(
            value: Country(name: L10n.sorryWeDonTKnowASuchCountry, dialCode: "", code: "", emoji: "🏴"),
            isSelected: false,
            isEmpty: true
        )
    }
}
