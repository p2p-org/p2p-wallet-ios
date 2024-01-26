import Foundation

struct DeviceTokenInfo: Codable {
    let osName: String
    let osVersion: String
    let deviceModel: String

    enum CodingKeys: String, CodingKey {
        case osName = "os_name"
        case osVersion = "os_version"
        case deviceModel = "device_model"
    }
}
