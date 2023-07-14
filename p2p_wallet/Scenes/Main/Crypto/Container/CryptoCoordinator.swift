//
//  CryptoCoordinator.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 12/07/23.
//

import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import SwiftUI
import UIKit
import Wormhole

/// The scenes that the `Crypto` scene can navigate to
enum CryptoNavigation: Equatable {
    // With tokens
    case buy
    case receive(publicKey: PublicKey)
    case send
    case swap
    case cashOut
    case earn
    case solanaAccount(SolanaAccount)
    case claim(EthereumAccount, WormholeClaimUserAction?)
    case actions([WalletActionType])
    // Empty
    case topUpCoin(Token)
    // Error
    case error(show: Bool)
}

/// Result type of the `Crypto` scene
typealias CryptoResult = Void

/// Coordinator of `Crypto` scene
final class CryptoCoordinator: Coordinator<CryptoResult> {
    
    // MARK: - Dependencies
    
    // MARK: - Properties
    
    /// Navigation controller that handle the navigation stack
    private let navigationController: UINavigationController
    
    /// Navigation subject
    private let navigation = PassthroughSubject<CryptoNavigation, Never>()
    
    // MARK: - Initializer
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Methods

    override func start() -> AnyPublisher<CryptoResult, Never> {
        // create viewmodel, view, uihostingcontroller
        let viewModel = CryptoViewModel(navigation: navigation)
        let actionsPanelViewModel = CryptoActionsPanelViewModel(navigation: navigation)
        let accountsViewModel = CryptoAccountsViewModel(navigation: navigation)
        let cryptoView = CryptoView(
            viewModel: viewModel,
            actionsPanelViewModel: actionsPanelViewModel,
            accountsViewModel: accountsViewModel
        )
        let cryptoVC = cryptoView.asViewController(withoutUIKitNavBar: false)
        cryptoVC.title = L10n.myCrypto
        navigationController.setViewControllers([cryptoVC], animated: false)
        
        // handle navigation
        navigation
            .flatMap { [unowned self] in
                navigate(to: $0)
            }
            .sink(receiveValue: {})
            .store(in: &subscriptions)
        
        // return publisher
        return cryptoVC.deallocatedPublisher()
    }
    
    // MARK: - Navigation

    private func navigate(to scene: CryptoNavigation) -> AnyPublisher<CryptoResult, Never> {
        switch scene {
//        case .detail:
//            let coordinator = CryptoDetailCoordinator()
//            return coordinate(to: coordinator)
//                .map {_ in ()}
//                .eraseToAnyPublisher()
        default:
            return Just(())
                .eraseToAnyPublisher()
        }
    }
}
