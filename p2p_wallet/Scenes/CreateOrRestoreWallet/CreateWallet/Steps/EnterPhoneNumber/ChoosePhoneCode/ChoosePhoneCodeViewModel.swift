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

struct SelectableCountry: Hashable {
    let country: Country
    var isSelected: Bool = false
}

final class ChoosePhoneCodeViewModel: BECollectionViewModel<SelectableCountry> {
    // MARK: - Dependencies

    // MARK: - Input

    var initialSelectedCountry: Country?
    let didClose = PassthroughSubject<Void, Never>()

    // MARK: - Output

//    @Published public private(set) var recommendation: String?

    // MARK: - Initializers

    // MARK: - Methods

    override func createRequest() async throws -> [SelectableCountry] {
        let initialSelectedCountry = initialSelectedCountry
        if self.initialSelectedCountry != nil {
            self.initialSelectedCountry = nil
        }
        return try await CountriesAPIImpl().fetchCountries()
            .map { .init(country: $0, isSelected: $0.code == initialSelectedCountry?.code) }
    }
}
