//
//  CryptoViewModel.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 12/07/23.
//

import Combine
import Foundation
import Resolver

/// ViewModel of `Crypto` scene
final class CryptoViewModel: BaseViewModel, ObservableObject {

    // MARK: - Properties
    
    @Published private(set) var balance: String = "0"
    @Published private(set) var actions: [WalletActionType] = [.receive, .swap]
    @Published private(set) var state: State = .pending
    
    /// Navigation subject (passed from Coordinator)
    let navigation: PassthroughSubject<CryptoNavigation, Never>
    
    // MARK: - Initializers
    
    init(navigation: PassthroughSubject<CryptoNavigation, Never>) {
        self.navigation = navigation
        super.init()
    }
    
}

extension CryptoViewModel {
    enum State {
        case pending
        case empty
        case tokens
    }
}
