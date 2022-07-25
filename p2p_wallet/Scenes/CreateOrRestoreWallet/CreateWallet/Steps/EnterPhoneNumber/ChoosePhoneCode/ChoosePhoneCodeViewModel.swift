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

    // MARK: - Input

    var initialSelectedCountry: Country?
    let didClose = PassthroughSubject<Void, Never>()
    @Published var keyword: String = ""

    // MARK: - Output

//    @Published public private(set) var recommendation: String?

    // MARK: - Initializers

    init() {
        super.init()
        $keyword
            .sink { [weak self] keyword in
                guard let self = self else { return }
                if keyword.isEmpty {
                    self.overrideData(by: self.cachedResult)
                    return
                }
                let newData = self.cachedResult.filteredByKeyword(keyword: keyword)
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
            .filteredByKeyword(keyword: keyword)
    }
}
