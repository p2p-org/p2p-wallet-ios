import Combine
import Foundation
import Onboarding

class BaseOTPViewModel: BaseViewModel, ObservableObject {
    /// Toaster error
    @Published public var error: String?

    @MainActor
    internal func showError(error: Error?) {
        var errorText = L10n.SomethingWentWrong.pleaseTryAgain
        if let error = error as? APIGatewayError {
            switch error {
            case .wait10Min:
                errorText = L10n.pleaseWait10MinAndWillAskForNewOTP
            case .invalidSignature:
                errorText = L10n.notValidSignature
            case .parseError:
                errorText = L10n.parseError
            case .invalidRequest:
                errorText = L10n.invalidRequest
            case .methodNotFound:
                errorText = L10n.methodNotFound
            case .invalidParams:
                errorText = L10n.invalidParams
            case .internalError:
                errorText = L10n.internalError
            case .everythingIsBroken:
                errorText = L10n.everythingIsBroken
            case .retry:
                errorText = L10n.pleaseRetryOperation
            case .alreadyConfirmed:
                errorText = L10n.ThisPhoneHasAlreadyBeenConfirmed.changePhoneNumber
            case .publicKeyAndPhoneExists:
                errorText = L10n.ThisPhoneHasAlreadyBeenConfirmed.changePhoneNumber
            case .invalidOTP:
                errorText = L10n.InvalidValueOfOTP.pleaseTryAgainToInputCorrectValueOfOTP
            case .youRequestOTPTooOften:
                errorText = L10n.YouRequestOTPTooOften.tryLater
            default:
                errorText = L10n.SomethingWentWrong.pleaseTryAgain
            }
        }
        self.error = errorText

        DefaultLogManager.shared.log(event: "Enter SMS: \(error?.readableDescription ?? errorText)", logLevel: .error)
    }
}
