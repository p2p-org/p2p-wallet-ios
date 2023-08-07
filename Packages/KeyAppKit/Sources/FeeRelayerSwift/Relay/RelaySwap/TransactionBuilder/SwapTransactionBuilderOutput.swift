import Foundation
import OrcaSwapSwift
import SolanaSwift

struct SwapTransactionBuilderOutput {
    var userSource: PublicKey?
    var sourceWSOLNewAccount: KeyPair?

    var transitTokenMintPubkey: PublicKey?
    var transitTokenAccountAddress: PublicKey?
    var needsCreateTransitTokenAccount: Bool?

    var destinationNewAccount: KeyPair?
    var userDestinationTokenAccountAddress: PublicKey?

    var instructions = [TransactionInstruction]()
    var additionalTransaction: PreparedTransaction?

    var signers: [KeyPair] = []

    // Building fee
    var accountCreationFee: Lamports = 0
    var additionalPaybackFee: UInt64 = 0
}
