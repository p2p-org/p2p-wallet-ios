import Foundation
import SolanaSwift

struct RawAccount: Codable, Hashable {
    let name: String?
    let phrase: String
    let derivablePath: DerivablePath
}
