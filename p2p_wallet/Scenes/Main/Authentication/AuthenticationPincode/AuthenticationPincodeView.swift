import Combine
import SwiftUI
import KeyAppUI

struct AuthenticationPincodeView: View {
    @ObservedObject private var viewModel: AuthenticationPincodeViewModel
    
    init(viewModel: AuthenticationPincodeViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            content
        }
    }
    
    private var content: some View {
        PinCodeView(
            title: L10n.enterYourPIN,
            showBiometry: true,
            showForgetPin: true,
            correctPincode: "111111",
            maxAttemptsCount: 3,
            resetingDelayInSeconds: 1
        ) {
            // Handle pincode success
        } onFailed: {
            // Handle pincode failed
        } onFailedAndExceededMaxAttempts: {
            // Handle pincode failure with maximum attempts exceeded
        } onForgetPIN: {
            // Handle on foregetPIN
        }
        .alert(item: $viewModel.snackbar) { snackbar in
            Alert(
                title: Text(snackbar.title),
                message: Text(snackbar.message),
                dismissButton: .default(Text("OK"), action: {
                    viewModel.handleSnackbarAction()
                })
            )
        }
        .fullScreenCover(isPresented: $viewModel.showForgotModal) {
            AuthenticationForgotPINView()
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .frame(height: 420)
        }
//        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
//            leading: Button(action: {
//                viewModel.back.send()
//            }, label: {
//                Image(systemName: "arrow.backward")
//                    .foregroundColor(Color(Asset.Colors.night.color))
//            }),
            trailing: Button(action: {
                viewModel.infoDidTap.send()
            }, label: {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.primary)
            })
        )
        .onReceive(viewModel.back) { _ in
            // Handle back action
        }
        .onReceive(viewModel.infoDidTap) { _ in
            // Handle info button tap
        }
        .onReceive(viewModel.logout) { _ in
            // Handle logout action
        }
    }
}

struct PincodeView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationPincodeView(
            viewModel: .init(
                showFaceID: true
            )
        )
    }
}
