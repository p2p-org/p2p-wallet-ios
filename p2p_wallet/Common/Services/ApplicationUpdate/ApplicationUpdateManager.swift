import Combine
import Foundation

class ApplicationUpdateManager {
    enum State {
        case updateAvailable(Version)
        case noUpdate
    }

    private let provider: ApplicationUpdateProvider

    init(provider: ApplicationUpdateProvider) {
        self.provider = provider
    }

    var currentInstalledVersion: Version? {
        let appVersionKey = "CFBundleShortVersionString"
        guard let appVersionValue = Bundle.main.object(forInfoDictionaryKey: appVersionKey) as? String else {
            return nil
        }

        return try? Version(from: appVersionValue)
    }

    func isUpdateAvailable() async -> State {
        guard
            let appVersion = currentInstalledVersion,
            let storeAppVersion = try? await provider.info()
        else {
            return .noUpdate
        }

        print("[ApplicationUpdateManager]", appVersion, storeAppVersion)

        // Check
        if storeAppVersion.major > appVersion.major {
            return .updateAvailable(storeAppVersion)
        } else if storeAppVersion.minor > appVersion.minor {
            return .updateAvailable(storeAppVersion)
        } else if storeAppVersion.patch > appVersion.patch {
            return .updateAvailable(storeAppVersion)
        }

        return .noUpdate
    }

    func awareUser(version: Version) async {
        UserDefaults.standard.set(version.string, forKey: "application_user_awareness")
    }

    func isUserAwareAboutUpdate(version: Version) async -> Bool {
        guard let userAwareness = UserDefaults.standard.object(forKey: "application_user_awareness") as? String else {
            return false
        }

        if version.string == userAwareness {
            return true
        } else {
            return false
        }
    }
}
