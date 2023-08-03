import Foundation
import Lokalise
import UIKit

final class LokaliseAppDelegateService: NSObject, AppDelegateService {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Lokalise.shared.setProjectID(
            String.secretConfig("LOKALISE_PROJECT_ID")!,
            token: String.secretConfig("LOKALISE_TOKEN")!
        )

        #if !RELEASE
            Lokalise.shared.localizationType = .prerelease
        #else
            Lokalise.shared.localizationType = .release
        #endif

        Lokalise.shared.swizzleMainBundle()

        return true
    }

    func applicationDidBecomeActive(_: UIApplication) {
        Lokalise.shared.checkForUpdates { updated, error in
            print(updated, error)
        }
    }
}
