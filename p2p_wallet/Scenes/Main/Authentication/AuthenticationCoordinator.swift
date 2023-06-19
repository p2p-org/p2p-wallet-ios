import Foundation
import SwiftUI
import Combine
import UIKit
import Resolver

/// Structure that indicates the result of the `AuthenticationCoordinator`.
enum AuthenticationCoordinatorResult {
    /// Authentication success.
    case success
    /// Authentication failed and user has to log out.
    case logout
}

/// Coordinator of the authentication flow.
final class AuthenticationCoordinator: Coordinator<AuthenticationCoordinatorResult> {
    
    // MARK: - Dependencies
    
    private let authenticationService: AuthenticationService
    
    // MARK: - Properties
    
    /// The view controller from which the authentication flow will be presented
    private let presentingViewController: UIViewController

    /// Indicates whether the back button is available in the authentication flow
    private let isBackAvailable: Bool

    /// Indicates whether the authentication flow should be presented as full screen
    private let isFullscreen: Bool

    /// Subject that handles the result
    private let resultSubject = PassthroughSubject<AuthenticationCoordinatorResult, Never>()

    /// Main viewController of the flow
    private var mainViewController: UIViewController!

    /// ForgetPIN viewController
    private var forgetPinViewController: UIViewController?
    
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
    
    override func start() -> AnyPublisher<AuthenticationCoordinatorResult, Never> {
        // Detect if authentication is needed
        guard authenticationService.shouldAuthenticateUser() else {
            // Just return success without authentication
            return Just(.success).prefix(1).eraseToAnyPublisher()
        }
        
        // Create pincode view model and observe events
        let authenticationPincodeViewModel = AuthenticationPincodeViewModel(
            correctPincode: "111111"
        )

        authenticationPincodeViewModel.pincodeSuccess
            .sink { [weak resultSubject] in
                resultSubject?.send(.success)
            }
            .store(in: &subscriptions)

        authenticationPincodeViewModel.infoDidTap
            .sink { _ in
                Resolver.resolve(HelpCenterLauncher.self).launch()
            }
            .store(in: &subscriptions)

        authenticationPincodeViewModel.forgetPinDidTap
            .sink { [weak self] _ in
                self?.openForgotPIN()
            }
            .store(in: &subscriptions)

        authenticationPincodeViewModel.showSnackbar
            .sink { content in
                // TODO: showSnackbar
                
            }
            .store(in: &subscriptions)

        authenticationPincodeViewModel.showLastWarningMessage
            .sink { _ in
                // TODO: showLastWarningMessage
                
            }
            .store(in: &subscriptions)

        authenticationPincodeViewModel.logout
            .sink { _ in
                // TODO: logout
                
            }
            .store(in: &subscriptions)
        
        // Create view
        let authenticationPincodeView = NavigationView {
            AuthenticationPincodeView(
                viewModel: authenticationPincodeViewModel
            )
        }
        
        // Create hosting controller for pincode view
        mainViewController = UIHostingController(rootView: authenticationPincodeView)
        
        // Show pincode view as full screen
        if isFullscreen {
            mainViewController.modalPresentationStyle = .fullScreen
        }
        
        // Present pincode view from the presenting view controller
        presentingViewController.present(mainViewController, animated: true)
        
        // Dismiss vc when receiving result
        resultSubject
            .sink { [weak self] _ in
                self?.mainViewController.dismiss(animated: true)
            }
            .store(in: &subscriptions)
        
        // Return result on view deallocated
        return resultSubject
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .prefix(1)
            .eraseToAnyPublisher()
    }

    // MARK: - Internal navigation

    private func openForgotPIN(
        text: String? = L10n.ifYouForgetYourPINYouCanLogOutAndCreateANewOneWhenYouLogInAgain,
        height: CGFloat? = nil
    ) {
        var view = ForgetPinView(text: text ?? L10n.ifYouForgetYourPINYouCanLogOutAndCreateANewOneWhenYouLogInAgain)
        
        view.close = { [weak self] in
            self?.forgetPinViewController?.dismiss(animated: true)
        }
        view.onLogout = { [weak self] in
            guard let self else { return }
            self.forgetPinViewController?.dismiss(animated: true, completion: {
                self.mainViewController.showAlert(
                    title: L10n.doYouWantToLogOut,
                    message: L10n.youWillNeedYourSocialAccountOrPhoneNumberToLogIn,
                    buttonTitles: [L10n.logOut, L10n.stay],
                    highlightedButtonIndex: 1,
                    destroingIndex: 0
                ) { index in
                    guard index == 0 else { return }
                    self.resultSubject.send(.logout)
                }
            })
        }
        
        let transition = PanelTransition()
        transition.containerHeight = height == nil ? view.viewHeight : (height ?? 0)
        forgetPinViewController = UIHostingController(rootView: view)
        forgetPinViewController?.view.layer.cornerRadius = 20
        forgetPinViewController?.transitioningDelegate = transition
        forgetPinViewController?.modalPresentationStyle = .custom
        
        transition.dimmClicked
            .sink { [weak self] in
                self?.forgetPinViewController?.dismiss(animated: true)
            }
            .store(in: &subscriptions)
        
        mainViewController.present(forgetPinViewController!, animated: true)
    }
}
