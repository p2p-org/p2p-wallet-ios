import Firebase
import Foundation

protocol ApplicationUpdateProvider {
    func info() async throws -> Version
}

class FirebaseApplicationUpdateProvider: ApplicationUpdateProvider {
    func info() async throws -> Version {
        let remoteConfig = RemoteConfig.remoteConfig()
        let appVersion = remoteConfig.configValue(forKey: "app_version", source: .remote).stringValue

        guard let appVersion else {
            throw Version.VersionError.invalidFormat
        }

        return try Version(from: appVersion)
    }
}
