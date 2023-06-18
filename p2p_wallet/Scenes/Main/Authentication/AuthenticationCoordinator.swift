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
    private let isBackAvailable: Bool
    private let isFullscreen: Bool

    // MARK: - Initializer

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
        let authenticationPincodeViewModel = AuthenticationPincodeViewModel()
        let authenticationPincodeView = AuthenticationPincodeView(viewModel: authenticationPincodeViewModel)
//        let pincodeViewModel = PincodeViewModel(
//            state: .check,
//            isBackAvailable: isBackAvailable,
//            successNotification: "",
//            ignoreAuthHandler: true
//        )
//        let pincodeViewController = PincodeViewController(viewModel: pincodeViewModel)

        // info did tap
//        pincodeViewModel.infoDidTap
//            .sink(receiveValue: { [unowned self] in
//                helpLauncher.launch()
//            })
//            .store(in: &subscriptions)
    
        // cancellable pincode
//        if isBackAvailable {
//            pincodeViewController.onClose = { [weak self] in
//                self?.viewModel.authenticate(presentationStyle: nil)
//                if authSuccess == false {
//                    authStyle.onCancel?()
//                }
//            }
//        }

        // Create navigation
        let vc = UIHostingController(rootView: authenticationPincodeView)

        // Show pincode view as full screen
        if isFullscreen {
            vc.modalPresentationStyle = .fullScreen
        }
        presentingViewController.present(vc, animated: true)
        
        // Return result on view deallocated
        return vc.deallocatedPublisher()
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
