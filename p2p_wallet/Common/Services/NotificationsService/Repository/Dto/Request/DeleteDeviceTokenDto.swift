import Foundation

struct DeleteDeviceTokenDto: Encodable {
    let deviceToken: String
    let clientId: String
    let ethPubkey: String?
    let type = "device"

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case clientId = "client_id"
        case ethPubkey = "eth_pubkey"
        case type
    }
}
