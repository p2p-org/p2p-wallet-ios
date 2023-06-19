import Combine
import SwiftUI
import KeyAppUI

struct AuthenticationPincodeView: View {

    // MARK: - Constants

    private let maxAttemptsCount = 5
    
    // MARK: - Properties
    
    @ObservedObject private var viewModel: AuthenticationPincodeViewModel
    
    // MARK: - Initialization
    
    init(viewModel: AuthenticationPincodeViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        PinCodeView(
            title: L10n.enterYourPIN,
            isBiometryEnabled: Defaults.isBiometryEnabled,
            showForgetPin: true,
            correctPincode: viewModel.correctPincode,
            maxAttemptsCount: maxAttemptsCount,
            resetingDelayInSeconds: 1
        ) {
            // Handle pincode success
            viewModel.pincodeSuccess.send(())
        } onFailed: { attemptCount in
            // Show last warning message befor logging out
            if maxAttemptsCount - attemptCount == 2 {
                viewModel.showLastWarningMessage.send(())
            }
        } onFailedAndExceededMaxAttempts: {
            // Handle pincode failure with maximum attempts exceeded
            viewModel.logout.send(())
        } onForgetPIN: {
            // Handle on forgetPIN
            viewModel.forgetPinDidTap.send(())
        }
//            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
//                leading: Button(action: {
//                    viewModel.back.send()
//                }, label: {
//                    Image(systemName: "chevron.left")
//                        .foregroundColor(Color(Asset.Colors.night.color))
//                }),
                trailing: Button(action: {
                    viewModel.infoDidTap.send()
                }, label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.primary)
                })
            )
    }
}

// MARK: - Preview

struct PincodeView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationPincodeView(
            viewModel: .init(correctPincode: "111111")
        )
    }
}
