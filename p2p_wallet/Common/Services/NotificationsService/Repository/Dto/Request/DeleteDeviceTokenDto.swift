import Foundation

struct DeleteDeviceTokenDto: Encodable {
    let deviceToken: String
    let clientId: String
    let ethPubkey: String?
    let type = "device"
}
