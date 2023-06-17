import Foundation
import SwiftUI
import Combine
import UIKit

/// Coordinator of Authentication flow
final class AuthenticationCoordinator: Coordinator<Void> {

    // MARK: - Dependencies

    private let authenticationService: AuthenticationService

    // MARK: - Properties

    private let presentingViewController: UIViewController

    // MARK: - Initializer

    init(authenticationService: AuthenticationService, presentingViewController: UIViewController) {
        self.authenticationService = authenticationService
        self.presentingViewController = presentingViewController
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        // Detect if authentication is needed
        guard authenticationService.shouldAuthenticateUser() else {
            // Just return success without authentication
            return Just(()).prefix(1).eraseToAnyPublisher()
        }
        
        // Show pincode screen
        let viewModel = AuthenticationPincodeViewModel()
        let view = AuthenticationPincodeView(viewModel: viewModel)
        let vc = UIHostingController(rootView: view)
        
        presentingViewController.present(vc, animated: true)
        
        viewModel.pincodeDidVerify
            .sink { [weak vc] _ in
                vc?.dismiss(animated: true)
            }
            .store(in: &subscriptions)
        
        return vc.deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
