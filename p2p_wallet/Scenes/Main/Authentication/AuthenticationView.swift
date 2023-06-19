import Combine
import SwiftUI
import KeyAppUI

struct AuthenticationView: View {

    // MARK: - Constants

    private let maxAttemptsCount = 5
    
    // MARK: - Properties
    
    @ObservedObject private var viewModel: AuthenticationViewModel
    
    // MARK: - Initialization
    
    init(viewModel: AuthenticationViewModel) {
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
        ) { result in
            switch result {
            case .successWithPinCode, .successWithBiometry:
                viewModel.success.send(())
            case let .failed(attemptCount, exeededMaxAttempt):
                if exeededMaxAttempt {
                    viewModel.logout.send(())
                } else if maxAttemptsCount - attemptCount == 2 {
                    viewModel.showLastWarningMessage.send(())
                }
            }
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
        AuthenticationView(
            viewModel: .init(correctPincode: "111111")
        )
    }
}
