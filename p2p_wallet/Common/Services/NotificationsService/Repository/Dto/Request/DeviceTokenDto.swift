import Foundation

struct DeviceTokenDto: Encodable {
    let deviceToken: String
    let clientId: String
    let ethPubkey: String?
    let type = "device"
    let deviceInfo: DeviceTokenInfo?
}
