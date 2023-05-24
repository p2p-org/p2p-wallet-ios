import Foundation
import Intercom

final class IntercomAppDelegateService: NSObject, AppDelegateService {

    // MARK: - Properties

    private var helpCenterOpened: Bool = false
    
    // MARK: - Methods

    func applicationWillResignActive(_ application: UIApplication) {
        // get top most view controller
        let vc = UIApplication.topmostViewController()
        let vcType = String(describing: vc)
        print(String(describing: vc!))
        
        // Hide any presented intercom vc
        Intercom.hide()
        
        // Workaround for intercom view controller,
        // there is currently noway to detect that intercom opened or not
        guard let vc,
              String(describing: vc)
                    .hasPrefix("<ICMHomescreenViewController") ||
                String(describing: vc)
                    .hasPrefix("<ICMConversationViewController") ||
                String(describing: vc)
                    .hasPrefix("<ICMContentModalViewController") ||
                String(describing: vc)
                    .hasPrefix("<IntercomSDKPrivate.HelpCenterContainerViewController")
        else {
            helpCenterOpened = false
            return
        }
        
        helpCenterOpened = true
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        guard helpCenterOpened else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            Intercom.presentMessenger()
        }
    }
}
