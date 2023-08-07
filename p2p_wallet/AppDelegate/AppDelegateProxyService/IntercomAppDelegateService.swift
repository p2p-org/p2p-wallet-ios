import Foundation
import Intercom

final class IntercomAppDelegateService: NSObject, AppDelegateService {
    // MARK: - Methods

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Intercom.setDeviceToken(deviceToken) { error in
            #if DEBUG
                if let error {
                    print("Intercom.setDeviceToken error: ", error)
                }
            #endif
        }
    }

    func applicationWillResignActive(_: UIApplication) {
        // Hide any presented intercom vc
        Intercom.hide()
    }
}
