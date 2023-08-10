import Foundation

struct DeviceTokenResponseDto: Decodable {
    let deviceToken: String
    let timestamp: String
    let clientId: String
}
