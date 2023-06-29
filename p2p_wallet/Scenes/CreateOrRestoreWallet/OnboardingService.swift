import Onboarding
import Foundation

protocol OnboardingService: AnyObject {
    var lastState: CreateWalletFlowState? { get set }
}

final class OnboardingServiceImpl: OnboardingService {
    var lastState: CreateWalletFlowState? {
        get { validate(lastState: Defaults.onboardingLastState) }
        set { Defaults.onboardingLastState = newValue }
    }

    private func validate(lastState: CreateWalletFlowState?) -> CreateWalletFlowState? {
        switch lastState {
        case let .bindingPhoneNumber(
            email,
            authProvider,
            seedPhrase,
            ethPublicKey,
            deviceShare,
            .block(until, _, phoneNumber, data)
        ):
            if Date() >= until {
                return .bindingPhoneNumber(
                    email: email,
                    authProvider: authProvider,
                    seedPhrase: seedPhrase,
                    ethPublicKey: ethPublicKey,
                    deviceShare: deviceShare,
                    .enterPhoneNumber(
                        initialPhoneNumber: phoneNumber,
                        didSend: false,
                        resendCounter: nil,
                        data: data
                    )
                )
            } else {
                return lastState
            }
        case let .bindingPhoneNumber(
            email,
            authProvider,
            seedPhrase,
            ethPublicKey,
            deviceShare,
            .enterOTP(resendCounter, _, phoneNumber, data)
        ):
            return .bindingPhoneNumber(
                email: email,
                authProvider: authProvider,
                seedPhrase: seedPhrase,
                ethPublicKey: ethPublicKey,
                deviceShare: deviceShare,
                .enterPhoneNumber(
                    initialPhoneNumber: phoneNumber,
                    didSend: false,
                    resendCounter: resendCounter,
                    data: data
                )
            )
        default:
            return lastState
        }
    }
}
