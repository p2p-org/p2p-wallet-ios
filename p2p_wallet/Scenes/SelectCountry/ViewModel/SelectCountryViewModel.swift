//
//  SelectCountryViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 13.04.2023.
//

import Combine
import Foundation
import Resolver
import Moonpay

private extension String {
    static let neutralFlag = "🏳️‍🌈"
}

final class SelectCountryViewModel: ObservableObject {
    
    // Dependencies
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
    
    // MARK: - Init
    
    init(selectedCountry: Model) {
        self.selectedCountry = selectedCountry
        getCountries()
    }
    
    // MARK: - From View
    
    func countrySelected(index: Int) {
        let model = models[index]
        selectCountrySubject.send(model)
    }
    
    func currentCountrySelected() {
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
}

// MARK: - State

extension SelectCountryViewModel {
    enum State {
        case skeleton
        case loaded(models: [Model])
        case notFound
    }
    
    struct Model {
        let flag: String
        let title: String
    }
}

// MARK: - To Coordinator

extension SelectCountryViewModel {
    var selectCountry: AnyPublisher<(Model, buyAllowed: Bool), Never> { selectCountrySubject.eraseToAnyPublisher() }
    var currentSelected: AnyPublisher<Void, Never> { currentSelectedSubject.eraseToAnyPublisher() }
}
