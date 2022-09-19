import LocalAuthentication
import Onboarding

protocol BiometricsAuthProvider {
    var availabilityStatus: LABiometryType { get }
    func authenticate(authenticationPrompt: String, completion: @escaping (Bool, NSError?) -> Void)
}

final class BiometricsAuthProviderImpl: BiometricsAuthProvider {
    var availabilityStatus: LABiometryType {
        _ = context.canEvaluatePolicy(policy, error: nil)
        return context.biometryType
    }

    private let context = LAContext()
    private let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics

    func authenticate(authenticationPrompt: String, completion: @escaping (Bool, NSError?) -> Void) {
        context.localizedFallbackTitle = ""
        context
            .evaluatePolicy(policy, localizedReason: authenticationPrompt) { success, error in
                DispatchQueue.main.async {
                    completion(success, error as? NSError)
                }
            }
    }
}

extension BiometricsAuthProvider {
    func authenticate(completion: @escaping (Bool, NSError?) -> Void) {
        let prompt = L10n.insteadOfAPINCodeYouCanAccessTheAppUsing(availabilityStatus.stringValue)
        authenticate(authenticationPrompt: prompt, completion: completion)
    }
}
