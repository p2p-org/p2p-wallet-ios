import Foundation
import OrcaSwapSwift
import SolanaSwift

extension SwapTransactionBuilderImpl {
    func checkClosingAccount(
        owner: PublicKey,
        feePayer: PublicKey,
        destinationTokenMint: PublicKey,
        minimumTokenAccountBalance: UInt64,
        env: inout SwapTransactionBuilderOutput
    ) throws {
        if let newAccount = env.sourceWSOLNewAccount {
            env.instructions.append(contentsOf: [
                TokenProgram.closeAccountInstruction(
                    account: newAccount.publicKey,
                    destination: owner,
                    owner: owner
                ),
            ])
        }
        // close destination
        if let newAccount = env.destinationNewAccount, destinationTokenMint == .wrappedSOLMint {
            env.instructions.append(contentsOf: [
                TokenProgram.closeAccountInstruction(
                    account: newAccount.publicKey,
                    destination: owner,
                    owner: owner
                ),
                SystemProgram.transferInstruction(
                    from: owner,
                    to: feePayer,
                    lamports: minimumTokenAccountBalance
                ),
            ])
            env.accountCreationFee -= minimumTokenAccountBalance
        }
    }
}
