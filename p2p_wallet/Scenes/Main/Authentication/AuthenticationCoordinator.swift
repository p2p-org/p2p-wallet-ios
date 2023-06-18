import Foundation
import SwiftUI
import Combine
import UIKit

/// Coordinator of the authentication flow.
final class AuthenticationCoordinator: Coordinator<Void> {
    
    // MARK: - Dependencies
    
    private let authenticationService: AuthenticationService
    
    // MARK: - Properties
    
    /// The view controller from which the authentication flow will be presented
    private let presentingViewController: UIViewController

    /// Indicates whether the back button is available in the authentication flow
    private let isBackAvailable: Bool

    //. Indicates whether the authentication flow should be presented as full screen
    private let isFullscreen: Bool
    
    // MARK: - Initializer
    
    /// Initializes the authentication coordinator.
    ///
    /// - Parameters:
    ///   - authenticationService: The authentication service used for authentication.
    ///   - presentingViewController: The view controller from which the authentication flow will be presented.
    ///   - isBackAvailable: Indicates whether the back button is available in the authentication flow.
    ///   - isFullscreen: Indicates whether the authentication flow should be presented as full screen.
    init(
        authenticationService: AuthenticationService,
        presentingViewController: UIViewController,
        isBackAvailable: Bool,
        isFullscreen: Bool
    ) {
        self.authenticationService = authenticationService
        self.presentingViewController = presentingViewController
        self.isBackAvailable = isBackAvailable
        self.isFullscreen = isFullscreen
    }
    
    // MARK: - Methods
    
    override func start() -> AnyPublisher<Void, Never> {
        // Detect if authentication is needed
        guard authenticationService.shouldAuthenticateUser() else {
            // Just return success without authentication
            return Just(()).prefix(1).eraseToAnyPublisher()
        }
        
        // Create pincode view
        let authenticationPincodeViewModel = AuthenticationPincodeViewModel(
            showFaceID: true
        )
        let authenticationPincodeView = AuthenticationPincodeView(
            viewModel: authenticationPincodeViewModel
        )
        
        // Create hosting controller for pincode view
        let vc = UIHostingController(rootView: authenticationPincodeView)
        
        // Show pincode view as full screen
        if isFullscreen {
            vc.modalPresentationStyle = .fullScreen
        }
        
        // Present pincode view from the presenting view controller
        presentingViewController.present(vc, animated: true)
        
        // Return result on view deallocated
        return vc.deallocatedPublisher()
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
