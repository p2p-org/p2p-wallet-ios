import Foundation

public struct StrigaWhitelistAddressResponse: Codable {
    var id: String
    var status: String
    var address: String
    var currency: String
    var label: String?
    var network: Network

    public struct Network: Codable {
        var name: String
        var type: String
        var contractAddress: String
    }
}

public struct StrigaWhitelistAddressesResponse: Codable {
    var addresses: [StrigaWhitelistAddressResponse]
}

public enum StrigaWhitelistAddressError: String {
    case alreadyWhitelisted = "00013"
}
