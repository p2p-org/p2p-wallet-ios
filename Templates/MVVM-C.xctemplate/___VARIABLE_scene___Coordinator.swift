//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import Combine
import Foundation
import Resolver
import SwiftUI
import UIKit

/// The scenes that the `___VARIABLE_scene___` scene can navigate to
enum ___VARIABLE_scene___Navigation: Equatable {
//    case detail
}

/// Result type of the `___VARIABLE_scene___` scene
typealias ___VARIABLE_scene___Result = Void

/// Coordinator of `___VARIABLE_scene___` scene
final class ___VARIABLE_scene___Coordinator: Coordinator<___VARIABLE_scene___Result> {
    
    // MARK: - Dependencies
    
    // MARK: - Properties
    
    /// Navigation controller that handle the navigation stack
    private let navigationController: UINavigationController
    
    /// Navigation subject
    private let navigation = PassthroughSubject<___VARIABLE_scene___Navigation, Never>()
    
    // MARK: - Initializer
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Methods

    override func start() -> AnyPublisher<___VARIABLE_scene___Result, Never> {
        // create viewmodel, view, uihostingcontroller
        let viewModel = ___VARIABLE_scene___ViewModel(navigation: navigation)
        let view = ___VARIABLE_scene___View(viewModel: viewModel)
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
        return vc.dellocatedPublisher
    }
    
    // MARK: - Navigation

    private func navigate(to scene: ___VARIABLE_scene___Navigation) -> AnyPublisher<___VARIABLE_scene___Result, Never> {
        switch scene {
//        case .detail:
//            let coordinator = ___VARIABLE_scene___DetailCoordinator()
//            return coordinate(to: coordinator)
//                .map {_ in ()}
//                .eraseToAnyPublisher()
//        default:
//            return Just(())
//                .eraseToAnyPublisher()
        }
    }
}
