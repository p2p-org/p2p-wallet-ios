import LocalAuthentication
import Resolver

class BaseICloudRestoreViewModel: BaseViewModel, ObservableObject {
    @Injected var notificationService: NotificationService
    @Injected private var biometricsProvider: BiometricsAuthProvider

    func authenticate(completion: @escaping (Bool) -> Void) {
        biometricsProvider.authenticate { [weak self] success, authError in
            guard let self = self else { return }
            if success || self.canBeSkipped(error: authError) {
                completion(true)
            } else {
                if authError?.code == LAError.biometryLockout.rawValue {
                    self.notificationService.showDefaultErrorNotification()
                }
                completion(false)
            }
        }
    }

    private func canBeSkipped(error: NSError?) -> Bool {
        guard let error = error else { return true }
        switch error.code {
        case LAError.biometryNotEnrolled.rawValue:
            return true
        case LAError.biometryNotAvailable.rawValue:
            return true
        default:
            return false
        }
    }
}
