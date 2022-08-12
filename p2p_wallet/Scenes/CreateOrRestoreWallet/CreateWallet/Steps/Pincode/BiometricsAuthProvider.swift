import LocalAuthentication
import Onboarding

protocol BiometricsAuthProvider: SecurityStatusProvider {
    var availabilityStatus: LABiometryType { get }
    func authenticate(authenticationPrompt: String, completion: @escaping (Bool, NSError?) -> Void)
}

final class BiometricsAuthProviderImpl: BiometricsAuthProvider {
    var isBiometryAvailable: Bool {
        availabilityStatus == .faceID || availabilityStatus == .touchID
    }

    var availabilityStatus: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(policy, error: nil)
        return context.biometryType
    }

    private let context = LAContext()
    private let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics

    func authenticate(authenticationPrompt: String, completion: @escaping (Bool, NSError?) -> Void) {
        context
            .evaluatePolicy(policy, localizedReason: authenticationPrompt) { success, error in
                DispatchQueue.main.async {
                    completion(success, error as? NSError)
                }
            }
    }
}
