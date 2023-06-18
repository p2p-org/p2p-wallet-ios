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
        ZStack {
            Color(Asset.Colors.lime.color)
                .ignoresSafeArea()
            
            VStack {
                Image(uiImage: .lockPincode)
                    .resizable()
                    .frame(width: 113.adaptiveHeight, height: 106.adaptiveHeight)
                    .padding(.top, 31)
                    .padding(.bottom, 33)
                
                Spacer()
                
                Text(viewModel.title)
                    .font(uiFont: .font(of: .title2, weight: .regular))
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 24.adaptiveHeight) {
                    PinCodeView(
                        showBiometry: true,
                        correctPincode: "111111",
                        maxAttemptsCount: 3,
                        resetingDelayInSeconds: 1
                    ) {
                        // Handle pincode success
                    } onFailed: {
                        // Handle pincode failed
                    } onFailedAndExceededMaxAttempts: {
                        // Handle pincode failure with maximum attempts exceeded
                    }
                    
                    if viewModel.showForgetPin {
                        Button(action: {
                            viewModel.showForgotModal = true
                        }, label: {
                            Text("I forgot PIN")
                                .font(uiFont: .font(of: .text1))
                                .foregroundColor(Color(Asset.Colors.sky.color))
                        })
                        .padding(.bottom, 34.adaptiveHeight)
                    }
                }
                .padding(.top, 56)
                
                Spacer()
            }
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
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                viewModel.back.send()
            }, label: {
                Image(systemName: "arrow.backward")
                    .foregroundColor(Color(Asset.Colors.night.color))
            }),
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
                title: L10n.enterYourPIN,
                showForgetPin: true,
                showFaceID: true
            )
        )
    }
}
