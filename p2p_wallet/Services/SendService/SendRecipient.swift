import Foundation

struct SendRecipient: Hashable {
    init(address: String, name: String?, hasNoFunds: Bool, hasNoInfo: Bool = false) {
        self.address = address
        self.name = name
        self.hasNoFunds = hasNoFunds
        self.hasNoInfo = hasNoInfo
    }

    let address: String
    let name: String?
    let hasNoFunds: Bool
    let hasNoInfo: Bool
}
