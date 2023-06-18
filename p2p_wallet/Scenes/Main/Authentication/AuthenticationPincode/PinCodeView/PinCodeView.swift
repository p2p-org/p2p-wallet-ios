import Foundation
import SwiftUI

struct PinCodeView: View {
    private let pincodeLength = 6
    
    @StateObject private var viewModel: PinCodeViewModel
    
    private var onSuccess: (() -> Void)?
    private var onFailed: (() -> Void)?
    private var onFailedAndExceededMaxAttempts: (() -> Void)?
    
    init(
        showBiometry: Bool,
        correctPincode: String? = nil,
        maxAttemptsCount: Int? = nil,
        onSuccess: (() -> Void)? = nil,
        onFailed: (() -> Void)? = nil,
        onFailedAndExceededMaxAttempts: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: PinCodeViewModel(
            showBiometry: showBiometry,
            correctPincode: correctPincode,
            maxAttemptsCount: maxAttemptsCount
        ))
        self.onSuccess = onSuccess
        self.onFailed = onFailed
        self.onFailedAndExceededMaxAttempts = onFailedAndExceededMaxAttempts
    }
    
    var body: some View {
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
            #if DEBUG
            Text(viewModel.currentPincode ?? "<debug: pincode>")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            #endif
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
            showBiometry: true,
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
