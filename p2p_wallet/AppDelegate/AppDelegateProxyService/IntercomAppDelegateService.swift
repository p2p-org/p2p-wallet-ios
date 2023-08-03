import Foundation
import Intercom

final class IntercomAppDelegateService: NSObject, AppDelegateService {
    // MARK: - Methods

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Intercom.setDeviceToken(deviceToken) { error in
            guard let error else { return }
            print("Intercom.setDeviceToken error: ", error)
        }
    }

    func applicationWillResignActive(_: UIApplication) {
        // Hide any presented intercom vc
        Intercom.hide()
    }
}
