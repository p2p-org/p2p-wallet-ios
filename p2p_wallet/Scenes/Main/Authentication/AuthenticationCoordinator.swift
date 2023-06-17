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
        
        // Create pincode view
        let viewModel = AuthenticationPincodeViewModel()
        let view = AuthenticationPincodeView(viewModel: viewModel)
        let vc = UIHostingController(rootView: view)
        
        // Show pincode view as full screen
        vc.modalPresentationStyle = .fullScreen
        presentingViewController.present(vc, animated: true)
        
        // Observe verification and dismiss view
        viewModel.pincodeDidVerify
            .sink { [weak vc] _ in
                vc?.dismiss(animated: true)
            }
            .store(in: &subscriptions)
        
        // Return result on view deallocated
        return vc.deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
