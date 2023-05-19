import Foundation

struct CreateNameAlertLoggerErrorMessage: Codable {
    let name: String
    let error: String
    var platform: String = "iOS \(UIDevice.current.systemVersion)"
    var appVersion: String = AppInfo.appVersionDetail
    var timestamp: String = "\(Int64(Date().timeIntervalSince1970 * 1000))"
    let userPubKey: String

    enum CodingKeys: String, CodingKey {
        case platform
        case appVersion
        case timestamp
        case name
        case error = "name_service_error"
        case userPubKey = "user_pubkey"
    }
}
