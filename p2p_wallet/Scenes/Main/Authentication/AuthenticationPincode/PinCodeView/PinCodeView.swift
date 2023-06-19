import Foundation
import SwiftUI
import KeyAppUI

typealias AttemptCount = Int

struct PinCodeView: View {
    // MARK: - Constants
    
    /// The length of the PIN code.
    private let pincodeLength = 6
    
    // MARK: - State and Callbacks
    
    @StateObject private var viewModel: PinCodeViewModel
    
    /// A callback closure to be called when the PIN code is successfully entered.
    private var onSuccess: (() -> Void)?
    
    /// A callback closure to be called when the PIN code entry fails.
    private var onFailed: ((AttemptCount) -> Void)?
    
    /// A callback closure to be called when the maximum number of failed attempts is exceeded.
    private var onFailedAndExceededMaxAttempts: (() -> Void)?
    
    /// A callback closure to be called when the "Forgot PIN" button is tapped.
    private var onForgetPIN: (() -> Void)?
    
    // MARK: - Initializer
    
    /// Initializes the PinCodeView.
    /// - Parameters:
    ///   - title: The title to be displayed in the view.
    ///   - showBiometry: A boolean value indicating whether biometry (e.g., Touch ID, Face ID) should be shown as an option.
    ///   - showForgetPin: A boolean value indicating whether the "Forgot PIN" button should be shown.
    ///   - correctPincode: The correct PIN code for validation. If `nil`, no validation will be performed.
    ///   - maxAttemptsCount: The maximum number of failed attempts allowed before `onFailedAndExceededMaxAttempts` closure is called.
    ///   - resetingDelayInSeconds: The delay in seconds before resetting the PIN code after a failed attempt. If `nil`, no reset will occur.
    ///   - onSuccess: A closure to be called when the PIN code is successfully entered.
    ///   - onFailed: A closure to be called when the PIN code entry fails.
    ///   - onFailedAndExceededMaxAttempts: A closure to be called when the maximum number of failed attempts is exceeded.
    ///   - onForgetPIN: A closure to be called when the "Forgot PIN" button is tapped.
    init(
        title: String,
        showBiometry: Bool,
        showForgetPin: Bool,
        correctPincode: String? = nil,
        maxAttemptsCount: Int? = nil,
        resetingDelayInSeconds: Int?,
        onSuccess: (() -> Void)? = nil,
        onFailed: ((AttemptCount) -> Void)? = nil,
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
    
    // MARK: - View Body
    
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
    
    // MARK: - Content
    
    private var content: some View {
        VStack(spacing: viewModel.stackViewSpacing) {
            PinCodeDotsView(
                numberOfDigits: viewModel.currentPincode?.count ?? 0,
                pincodeLength: pincodeLength,
                isPresentingError: viewModel.isPresentingError
            )
            NumpadView(
                showBiometry: viewModel.showBiometry,
                isDeleteButtonHidden: (viewModel.currentPincode?.count ?? 0) == 0,
                isLocked: viewModel.isLocked,
                didChooseNumber: { digit in
                    viewModel.add(digit: digit)
                },
                didTapDelete: {
                    viewModel.backspace()
                },
                didTapBiometry: {
                    viewModel.validateBiometry()
                }
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
            onFailed?(viewModel.attemptsCount)
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
            resetingDelayInSeconds: 1,
            onSuccess: {
                
            },
            onFailed: { _ in
                
            },
            onFailedAndExceededMaxAttempts: {
                
            }
        )
    }
}
