//
//  CryptoCoordinator.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 12/07/23.
//

import Combine
import Foundation
import Resolver
import SwiftUI
import UIKit

/// The scenes that the `Crypto` scene can navigate to
enum CryptoNavigation: Equatable {
//    case detail
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
        let view = CryptoView(viewModel: viewModel)
        let vc = UIHostingController(rootView: view)
        
        // push hostingcontroller
        navigationController.pushViewController(vc, animated: true)
        
        // handle navigation
        navigation
            .flatMap { [unowned self] in
                navigate(to: $0)
            }
            .sink(receiveValue: {})
            .store(in: &subscriptions)
        
        // return publisher
        return vc.deallocatedPublisher()
    }
    
    // MARK: - Navigation

    private func navigate(to scene: CryptoNavigation) -> AnyPublisher<CryptoResult, Never> {
        switch scene {
//        case .detail:
//            let coordinator = CryptoDetailCoordinator()
//            return coordinate(to: coordinator)
//                .map {_ in ()}
//                .eraseToAnyPublisher()
//        default:
//            return Just(())
//                .eraseToAnyPublisher()
        }
    }
}
