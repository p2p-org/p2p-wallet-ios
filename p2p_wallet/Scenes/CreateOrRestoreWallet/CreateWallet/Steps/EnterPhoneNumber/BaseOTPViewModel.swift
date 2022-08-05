import Combine
import Foundation

class BaseOTPViewModel: BaseViewModel {
    /// Toaster error
    @Published public var error: String?

    @MainActor
    internal func showError(error: Error?) {
        var errorText = error?.readableDescription
        if let error = error as? SMSServiceError {
            switch error {
            case .wait10Min:
                errorText = L10n.pleaseWait10MinAndWillAskForNewOTP
            case .invalidSignature:
                errorText = L10n.notValidSignature
            case .parseError:
                errorText = L10n.parseError
            case .invalidRequest:
                errorText = L10n.invalidRequest
            case .methodNotFOund:
                errorText = L10n.methodNotFound
            case .invalidParams:
                errorText = L10n.invalidParams
            case .internalError:
                errorText = L10n.internalError
            case .everytingIsBroken:
                errorText = L10n.everythingIsBroken
            case .retry:
                errorText = L10n.pleaseRetryOperation
            case .changePhone:
                errorText = L10n.SMSWillNotBeDelivered.pleaseChangePhoneNumber
            case .alreadyConfirmed:
                errorText = L10n.ThisPhoneHasAlreadyBeenConfirmed.changePhoneNumber
            case .callNotPermit:
                errorText = L10n.CallNotPermit.UseSms.mayBeItHelps
            case .pubkeyExists:
                errorText = L10n.pubkeySolanaAlreadyExists
            case .pubkeyAndPhoneExists:
                errorText = L10n.pubkeySolanaAndPhoneNumberAlreadyExists
            case .invalidValue:
                errorText = L10n.InvalidValueOfOTP.pleaseTryAgainToInputCorrectValueOfOTP
            }
        }
        self.error = errorText

        if let errorText = errorText {
            DefaultLogManager.shared.log(event: "Enter SMS: \(errorText)", logLevel: .error)
        }
    }
}
