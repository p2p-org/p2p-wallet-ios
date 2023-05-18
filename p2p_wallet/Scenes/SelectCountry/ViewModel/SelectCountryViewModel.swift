//
//  SelectCountryViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 13.04.2023.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import Moonpay

private extension String {
    static let neutralFlag = "🏳️‍🌈"
}

final class SelectCountryViewModel: ObservableObject {
    
    // Dependencies
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var moonpayProvider: Moonpay.Provider
    
    // Private variables
    private var models = [(Model, buyAllowed: Bool)]()
    
    // Subjects
    private let selectCountrySubject = PassthroughSubject<(Model, buyAllowed: Bool), Never>()
    private let currentSelectedSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - To View
    
    let selectedCountry: Model
    @Published var state = State.skeleton
    
    // MARK: - From View
    
    @Published var searchText = "" {
        didSet {
            searchItem()
        }
    }
    @Published var isSearching = false {
        didSet {
            isSearchingChanged()
        }
    }
    
    // MARK: - Init
    
    init(selectedCountry: Model) {
        self.selectedCountry = selectedCountry
        getCountries()
    }
    
    // MARK: - From View
    
    func onAppear() {
        analyticsManager.log(event: .regionBuyScreenOpen)
    }
    
    func countrySelected(model: Model) {
        guard let model = (models.first { $0.0 == model }) else { return }
        analyticsManager.log(event: .regionBuyResultClick(country: model.0.title))
        selectCountrySubject.send(model)
    }
    
    func currentCountrySelected() {
        analyticsManager.log(event: .regionBuyResultClick(country: selectedCountry.title))
        currentSelectedSubject.send()
    }
    
    // MARK: - Private
    
    private func getCountries() {
        Task {
            let countries = try await moonpayProvider.getCountries()
            
            await MainActor.run {
                var models = [(Model, buyAllowed: Bool)]()
                for country in countries {
                    let flag = country.code.asFlag ?? .neutralFlag
                    
                    if selectedCountry.title != country.name {
                        models.append((Model(flag: flag, title: country.name), buyAllowed: country.isBuyAllowed))
                    }
                    guard country.code == "US" else { continue }
                    
                    for state in (country.states ?? []) {
                        guard !state.isBuyAllowed else { continue }
                        let title = "\(country.name) (\(state.name))"
                        guard selectedCountry.title != title else { continue }
                        
                        models.append((
                            Model(flag: flag, title: "\(country.name) (\(state.name))"),
                            buyAllowed: state.isBuyAllowed
                        ))
                    }
                }
                state = .loaded(models: models.map { $0.0 })
                self.models = models
                
            }
        }
    }
    
    private func searchItem() {
        guard !searchText.isEmpty else {
            state = .loaded(models: models.map { $0.0 })
            return
        }
        
        let filteredItems = models.filter { $0.0.title.contains(searchText) }
        state = !filteredItems.isEmpty ? .loaded(models: filteredItems.map{ $0.0 }) : .notFound
    }
    
    private func isSearchingChanged() {
        guard isSearching else { return }
        analyticsManager.log(event: .regionBuySearchClick)
    }
}

// MARK: - State

extension SelectCountryViewModel {
    enum State {
        case skeleton
        case loaded(models: [Model])
        case notFound
    }
    
    struct Model: Equatable {
        let flag: String
        let title: String
        
        var id: String { title }
    }
}

// MARK: - To Coordinator

extension SelectCountryViewModel {
    var selectCountry: AnyPublisher<(Model, buyAllowed: Bool), Never> { selectCountrySubject.eraseToAnyPublisher() }
    var currentSelected: AnyPublisher<Void, Never> { currentSelectedSubject.eraseToAnyPublisher() }
}
