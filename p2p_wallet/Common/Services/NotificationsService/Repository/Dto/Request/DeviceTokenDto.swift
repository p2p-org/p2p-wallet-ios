import Foundation

struct DeviceTokenDto: Encodable {
    let deviceToken: String
    let clientId: String
    let ethPubkey: String?
    let type = "device"
    let deviceInfo: DeviceTokenInfo?

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case clientId = "client_id"
        case ethPubkey = "eth_pubkey"
        case type
        case deviceInfo = "device_info"
    }
}
