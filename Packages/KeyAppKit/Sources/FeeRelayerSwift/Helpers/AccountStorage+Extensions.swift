import Foundation
import SolanaSwift

extension SolanaAccountStorage {
    var pubkey: PublicKey {
        get throws {
            try account?.publicKey ?! FeeRelayerError.unauthorized
        }
    }

    var signer: KeyPair {
        get throws {
            try account ?! FeeRelayerError.unauthorized
        }
    }
}
