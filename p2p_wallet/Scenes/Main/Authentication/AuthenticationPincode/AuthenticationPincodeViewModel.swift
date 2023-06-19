import Combine
import SwiftUI

/// The view model class that manages the authentication pincode view.
class AuthenticationPincodeViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Properties

    /// The expected pincode.
    let correctPincode: String
    
    /// The snackbar model to show a brief message to the user.
    @Published var snackbar: SnackbarModel?
    
    // MARK: - Subjects
    
    /// Publishes the pincode string when the pincode authentication is successful via pincode.
    var pincodeSuccess = PassthroughSubject<Void, Never>()

    /// Publishes the pincode string when the pincode authentication is successful via biometry.
    var biometrySuccess = PassthroughSubject<Void, Never>()
    
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
    init(correctPincode: String) {
        self.correctPincode = correctPincode
    }
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
