//
//  SellInputViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2022.
//

import Foundation
import Combine

final class SellInputViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Properties
    
    @Published var baseAmount: Double?
    @Published var isEnteringBaseAmount: Bool = false
    
    @Published var quoteAmount: Double?
    @Published var isEnteringQuoteAmount: Bool = false
    
    @Published var exchangeRate: Double = .random(in: 13...13.99)
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        bind()
    }
    
    // MARK: - Binding
    
    private func bind() {
        // enter base amount
        Publishers.CombineLatest($baseAmount, $exchangeRate)
            .filter {[weak self] _ in
                self?.isEnteringBaseAmount == true
            }
            .map { baseAmount, exchangeRate in
                guard let baseAmount else {return nil}
                return baseAmount * exchangeRate
            }
            .assign(to: \.quoteAmount, on: self)
            .store(in: &subscriptions)
        
        // enter quote amount
        Publishers.CombineLatest($quoteAmount, $exchangeRate)
            .filter {[weak self] _ in
                self?.isEnteringQuoteAmount == true
            }
            .map { quoteAmount, exchangeRate in
                guard let quoteAmount, exchangeRate != 0 else {return nil}
                return quoteAmount / exchangeRate
            }
            .assign(to: \.baseAmount, on: self)
            .store(in: &subscriptions)
    }
}
