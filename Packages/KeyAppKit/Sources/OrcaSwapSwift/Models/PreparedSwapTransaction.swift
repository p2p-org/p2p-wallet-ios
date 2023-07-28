import Foundation
import SolanaSwift

public struct PreparedSwapTransaction {
    public let instructions: [TransactionInstruction]
    public let signers: [KeyPair]
    public let accountCreationFee: Lamports
}
