import Combine
import SwiftUI

class AuthenticationPincodeViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var showForgetPin: Bool = false
    @Published var showFaceid: Bool = false
    @Published var snackbar: SnackbarModel?
    @Published var showForgotModal: Bool = false
    
    var pincodeSuccess = PassthroughSubject<String, Never>()
    var pincodeFailed = PassthroughSubject<Void, Never>()
    var back = PassthroughSubject<Void, Never>()
    var infoDidTap = PassthroughSubject<Void, Never>()
    var logout = PassthroughSubject<Void, Never>()
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        // Initialize your variables and setup bindings or other logic
    }
    
    func biometricsTapped() {
        // Handle biometrics tap
    }
    
    func resetPincode() {
        // Reset pincode logic
    }
    
    func handleSnackbarAction() {
        // Handle snackbar action
    }
    
    func logoutUser() {
        // Logout user
    }
}

struct SnackbarModel: Identifiable {
    var id: String {
        title
    }
    let title: String
    let message: String
}
