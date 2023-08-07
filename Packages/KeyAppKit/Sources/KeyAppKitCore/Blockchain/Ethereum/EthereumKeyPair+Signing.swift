import Foundation
import Web3

public extension EthereumKeyPair {
    func sign(transaction: EthereumTransaction, chainID: EthereumQuantity) throws -> EthereumSignedTransaction {
        try transaction.sign(with: privateKey, chainId: chainID)
    }
}
