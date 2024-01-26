import Foundation

struct DeviceTokenResponseDto: Decodable {
    let deviceToken: String
    let timestamp: String
    let clientId: String

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case timestamp
        case clientId = "client_id"
    }
}
