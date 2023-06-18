import Foundation
import SwiftUI
import KeyAppUI

struct PinCodeView: View {
    private let pincodeLength = 6
    
    @StateObject private var viewModel: PinCodeViewModel
    
    private var onSuccess: (() -> Void)?
    private var onFailed: (() -> Void)?
    private var onFailedAndExceededMaxAttempts: (() -> Void)?
    private var onForgetPIN: (() -> Void)?
    
    init(
        title: String,
        showBiometry: Bool,
        showForgetPin: Bool,
        correctPincode: String? = nil,
        maxAttemptsCount: Int? = nil,
        resetingDelayInSeconds: Int? = nil,
        onSuccess: (() -> Void)? = nil,
        onFailed: (() -> Void)? = nil,
        onFailedAndExceededMaxAttempts: (() -> Void)? = nil,
        onForgetPIN: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: PinCodeViewModel(
            title: title,
            showForgetPin: showForgetPin,
            showBiometry: showBiometry,
            correctPincode: correctPincode,
            maxAttemptsCount: maxAttemptsCount,
            resetingDelayInSeconds: resetingDelayInSeconds
        ))
        self.onSuccess = onSuccess
        self.onFailed = onFailed
        self.onFailedAndExceededMaxAttempts = onFailedAndExceededMaxAttempts
        self.onForgetPIN = onForgetPIN
    }
    
    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .ignoresSafeArea()
            
            VStack {
                Image(uiImage: .lockPincode)
                    .resizable()
                    .frame(width: 113.adaptiveHeight, height: 106.adaptiveHeight)
                    .padding(.top, 31)
                    .padding(.bottom, 31)
                
                Text(viewModel.title)
                    .font(uiFont: .font(of: .title2, weight: .regular))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 56)
                
                content
                
                if viewModel.showForgetPin {
                    Button(action: {
                        onForgetPIN?()
                    }, label: {
                        Text("I forgot PIN")
                            .font(uiFont: .font(of: .text1))
                            .foregroundColor(Color(Asset.Colors.sky.color))
                    })
                    .padding(.top, 24.adaptiveHeight)
                    .padding(.bottom, 34.adaptiveHeight)
                }
                
                Spacer()
            }
        }
    }
    
    private var content: some View {
        VStack(spacing: viewModel.stackViewSpacing) {
            PinCodeDotsView(
                numberOfDigits: viewModel.currentPincode?.count ?? 0,
                pincodeLength: pincodeLength
            )
            NumpadView(
                showBiometry: viewModel.showBiometry,
                isDeleteButtonHidden: (viewModel.currentPincode?.count ?? 0) == 0,
                didChooseNumber: viewModel.add(digit:),
                didTapDelete: viewModel.backspace,
                didTapBiometry: viewModel.validateBiometry
            )
        }
        .onReceive(viewModel.$currentPincode) { _ in
            viewModel.validatePincode()
        }
        .onAppear {
            viewModel.reset()
        }
        .onReceive(viewModel.onSuccess) { _ in
            onSuccess?()
        }
        .onReceive(viewModel.onFailed) { _ in
            onFailed?()
        }
        .onReceive(viewModel.onFailedAndExceededMaxAttempts) { _ in
            onFailedAndExceededMaxAttempts?()
        }
    }
}

struct PinCodeView_Previews: PreviewProvider {
    static var previews: some View {
        PinCodeView(
            title: L10n.enterYourPIN,
            showBiometry: true,
            showForgetPin: true,
            correctPincode: "111111",
            maxAttemptsCount: 3,
            onSuccess: {
                
            },
            onFailed: {
                
            },
            onFailedAndExceededMaxAttempts: {
                
            }
        )
    }
}
