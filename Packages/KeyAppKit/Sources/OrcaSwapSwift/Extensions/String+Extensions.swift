import Foundation
import SolanaSwift

extension String {
    func toPublicKey() throws -> PublicKey {
        try PublicKey(string: self)
    }
}
