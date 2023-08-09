import Foundation
import SolanaSwift

struct DerivableAccount: Hashable, Identifiable {
    let derivablePath: DerivablePath
    let info: KeyPair
    var amount: Double?
    var price: Double?

    // additional
    var isBlured: Bool?

    var id: String {
        info.publicKey.base58EncodedString
    }
}
