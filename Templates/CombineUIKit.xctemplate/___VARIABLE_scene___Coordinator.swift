//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import Foundation
import Combine

class ___VARIABLE_scene___Coordinator: Coordinator<Void> {
    // MARK: - NavigationController

    private(set) var navigationController: UINavigationController?

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Error> {
        guard navigationController == nil else {
            return Fail(error: CoordinatorError.isAlreadyStarted)
                .eraseToAnyPublisher()
        }

        // Create root view controller
        let viewModel = ___VARIABLE_scene___ViewModel()
        let viewController = ___VARIABLE_scene___ViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: viewController)
//        navigationController?.modalPresentationStyle = .fullScreen

        return Empty()
            .eraseToAnyPublisher()
    }
    
    func navigate(viewModel: ___VARIABLE_scene___ViewModel) {
        guard let navigationController = navigationController else { return }
        let viewModel = ___VARIABLE_scene___DetailViewModel()
        let vc = ___VARIABLE_scene___DetailViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
