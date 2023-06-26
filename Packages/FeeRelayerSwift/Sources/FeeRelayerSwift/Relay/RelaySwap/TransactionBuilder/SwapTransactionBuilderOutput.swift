import Foundation
import OrcaSwapSwift
import SolanaSwift

struct SwapTransactionBuilderOutput {
    var userSource: PublicKey? = nil
    var sourceWSOLNewAccount: KeyPair? = nil
    
    var transitTokenMintPubkey: PublicKey?
    var transitTokenAccountAddress: PublicKey?
    var needsCreateTransitTokenAccount: Bool?

    var destinationNewAccount: KeyPair? = nil
    var userDestinationTokenAccountAddress: PublicKey? = nil

    var instructions = [TransactionInstruction]()
    var additionalTransaction: PreparedTransaction? = nil

    var signers: [KeyPair] = []

    // Building fee
    var accountCreationFee: Lamports = 0
    var additionalPaybackFee: UInt64 = 0
}
