import Foundation
import LocalAuthentication

protocol BiometricsAuthenticationProvider {
    var availabilityStatus: LABiometryType { get }

    func authenticate(authenticationPrompt: String, completion: @escaping (Bool) -> Void)
}

final class BiometricsAuthenticationProviderImpl: BiometricsAuthenticationProvider {
    var availabilityStatus: LABiometryType {
        LABiometryType.current
    }

    private let context = LAContext()

    func authenticate(authenticationPrompt: String, completion: @escaping (Bool) -> Void) {
        context
            .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                            localizedReason: authenticationPrompt)
            { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        debugPrint(error)
                    }
                    completion(success)
                }
            }
    }
}
