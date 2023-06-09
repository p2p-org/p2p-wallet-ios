import Foundation
import Intercom

final class IntercomAppDelegateService: NSObject, AppDelegateService {
    
    // MARK: - Methods

    func applicationWillResignActive(_ application: UIApplication) {
        // Hide any presented intercom vc
        Intercom.hide()
        
    }
}
