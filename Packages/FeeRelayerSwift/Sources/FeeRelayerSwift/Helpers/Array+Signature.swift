import Foundation
import SolanaSwift

extension Array where Element == Signature {
    func getSignature(index: Int) throws -> String {
        guard count > index else { throw FeeRelayerError.invalidSignature }
        guard let data = self[index].signature else { throw FeeRelayerError.invalidSignature }
        return Base58.encode(data)
    }
}
