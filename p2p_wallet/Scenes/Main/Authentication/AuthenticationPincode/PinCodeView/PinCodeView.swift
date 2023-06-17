import Foundation
import SwiftUI

struct PinCodeView: View {
    @StateObject private var viewModel: PinCodeViewModel
    
    private var onSuccess: (() -> Void)?
    private var onFailed: (() -> Void)?
    private var onFailedAndExceededMaxAttempts: (() -> Void)?
    
    init(
        correctPincode: String? = nil,
        maxAttemptsCount: Int? = nil,
        onSuccess: (() -> Void)? = nil,
        onFailed: (() -> Void)? = nil,
        onFailedAndExceededMaxAttempts: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: PinCodeViewModel(correctPincode: correctPincode, maxAttemptsCount: maxAttemptsCount))
        self.onSuccess = onSuccess
        self.onFailed = onFailed
        self.onFailedAndExceededMaxAttempts = onFailedAndExceededMaxAttempts
    }
    
    var body: some View {
        VStack(spacing: viewModel.stackViewSpacing) {
            PinCodeDotsView(numberOfDigits: viewModel.currentPincode?.count ?? 0)
            NumpadView(didChooseNumber: viewModel.add(digit:), didTapDelete: viewModel.backspace)
            Text("Error Label")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
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
