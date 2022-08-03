import Foundation
import LocalAuthentication

protocol BiometricsAuthProvider {
    var availabilityStatus: LABiometryType { get }

    func authenticate(authenticationPrompt: String, completion: @escaping (Bool) -> Void)
}

final class BiometricsAuthProviderImpl: BiometricsAuthProvider {
    var availabilityStatus: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(policy, error: nil)
        return context.biometryType
    }

    private let context = LAContext()
    private let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics

    func authenticate(authenticationPrompt: String, completion: @escaping (Bool) -> Void) {
        context
            .evaluatePolicy(policy, localizedReason: authenticationPrompt) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        debugPrint(error)
                    }
                    completion(success)
                }
            }
    }
}
