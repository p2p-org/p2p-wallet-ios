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
            // For Debug build or build from Firebase
            Lokalise.shared.localizationType = .prerelease
        #else
            let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
            if isTestFlight {
                // Use prerelease bundle for build from testflight
                Lokalise.shared.localizationType = .prerelease
            } else {
                // Use release bundle for build from store
                Lokalise.shared.localizationType = .release
            }
        #endif

        Lokalise.shared.swizzleMainBundle()

        return true
    }

    func applicationDidBecomeActive(_: UIApplication) {
        Lokalise.shared.checkForUpdates { updated, error in
            #if DEBUG
                if let error { print(error) }
                print(updated)
            #endif
        }
    }
}
