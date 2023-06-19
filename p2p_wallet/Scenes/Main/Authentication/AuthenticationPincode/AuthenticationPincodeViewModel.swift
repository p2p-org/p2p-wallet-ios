import Combine
import SwiftUI

/// The view model class that manages the authentication pincode view.
class AuthenticationPincodeViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Properties
    
    /// Indicates whether the "Face ID" option should be shown.
    let showFaceID: Bool
    
    /// The snackbar model to show a brief message to the user.
    @Published var snackbar: SnackbarModel?
    
    // MARK: - Subjects
    
    /// Publishes the pincode string when the pincode authentication is successful.
    var pincodeSuccess = PassthroughSubject<Void, Never>()
    
    /// Publishes a void value when the back button is tapped.
    var back = PassthroughSubject<Void, Never>()
    
    /// Publishes a void value when the info button is tapped.
    var infoDidTap = PassthroughSubject<Void, Never>()
    
    /// Publishes a void value when the forgetPIN button is tapped.
    var forgetPinDidTap = PassthroughSubject<Void, Never>()
    
    /// Publishes a void value when the forgetPIN button is tapped.
    var showSnackbar = PassthroughSubject<SnackbarModel, Never>()
    
    /// Publishes a void value when need to show last warning message.
    var showLastWarningMessage = PassthroughSubject<Void, Never>()
    
    /// Publishes a void value when the user logs out.
    var logout = PassthroughSubject<Void, Never>()
    
    // MARK: - Initialization
    
    /// Initializes the `AuthenticationPincodeViewModel` with the provided parameters.
    /// - Parameters:
    ///   - title: The title to be displayed in the pincode view.
    ///   - showForgetPin: Indicates whether the "Forgot Pin" option should be shown.
    ///   - showFaceID: Indicates whether the "Face ID" option should be shown.
    init(showFaceID: Bool) {
        self.showFaceID = showFaceID
    }
    
    // MARK: - Actions
    
//    /// Handles the tap on the biometrics option.
//    func biometricsTapped() {
//        // Handle biometrics tap
//    }
//
//    /// Resets the pincode.
//    func resetPincode() {
//        // Reset pincode logic
//    }
//
//    /// Handles the action triggered by the snackbar.
//    func handleSnackbarAction() {
//        // Handle snackbar action
//    }
//
//    /// Logs out the user.
//    func logoutUser() {
//        // Logout user
//    }
}

extension AuthenticationPincodeViewModel {
    /// Snackbar model to show to user
    struct SnackbarModel: Identifiable {
        /// The unique identifier for the snackbar model.
        var id: String {
            title
        }
        
        /// The title of the snackbar.
        let title: String
        
        /// The message of the snackbar.
        let message: String
    }
}
