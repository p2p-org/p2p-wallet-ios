import Combine
import SwiftUI
import KeyAppUI

struct AuthenticationPincodeView: View {
    @ObservedObject private var viewModel: AuthenticationPincodeViewModel
    
    init(viewModel: AuthenticationPincodeViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .ignoresSafeArea()
            
            VStack {
                Image(uiImage: .lockPincode)
                    .resizable()
                    .frame(width: 114, height: 107.adaptiveHeight)
                    .padding(.top, 70)
                    .padding(.bottom, 33)
                
                Spacer()
                
                Text(viewModel.title)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    PinCodeView(
                        correctPincode: "111111",
                        maxAttemptsCount: 3
                    ) {
                        // Handle pincode success
                    } onFailed: {
                        // Handle pincode success
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
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.showFaceID {
                    Button(action: {
                        viewModel.biometricsTapped()
                    }, label: {
                        Image("faceId")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    })
                }
            }
        })
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
