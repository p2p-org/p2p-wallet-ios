import Foundation
import SolanaSwift
import OrcaSwapSwift

extension SwapTransactionBuilderImpl {
    func checkDestination(
        owner: KeyPair,
        destinationMint: PublicKey,
        destinationAddress: PublicKey?,
        recentBlockhash: String,
        output: inout SwapTransactionBuilderOutput
    ) async throws {
        // if user has already given an spl address
        if let destinationAddress, destinationMint != .wrappedSOLMint {
            // return the address
            output.userDestinationTokenAccountAddress = destinationAddress
        }
        
        // else, find real destination
        else {
            let result = try await destinationAnalysator.analyseDestination(
                owner: owner.publicKey,
                mint: destinationMint
            )
            
            switch result {
            case .wsolAccount:
                // For native solana, create and initialize WSOL
                let destinationNewAccount = try await KeyPair(network: network)
                output.instructions.append(contentsOf: [
                    SystemProgram.createAccountInstruction(
                        from: feePayerAddress,
                        toNewPubkey: destinationNewAccount.publicKey,
                        lamports: minimumTokenAccountBalance,
                        space: AccountInfo.BUFFER_LENGTH,
                        programId: TokenProgram.id
                    ),
                    TokenProgram.initializeAccountInstruction(
                        account: destinationNewAccount.publicKey,
                        mint: destinationMint,
                        owner: owner.publicKey
                    ),
                ])
                
                // return the address
                output.userDestinationTokenAccountAddress = destinationNewAccount.publicKey
                output.accountCreationFee += minimumTokenAccountBalance
                output.destinationNewAccount = destinationNewAccount
            case .splAccount(let needsCreation):
                // For other token, get associated token address
                let associatedAddress = try PublicKey.associatedTokenAddress(
                    walletAddress: owner.publicKey,
                    tokenMintAddress: destinationMint
                )
                
                if needsCreation {
                    let instruction = try AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                        mint: destinationMint,
                        owner: owner.publicKey,
                        payer: feePayerAddress
                    )

                    // SPECIAL CASE WHEN WE SWAP FROM SOL TO NON-CREATED SPL TOKEN, THEN WE NEEDS ADDITIONAL TRANSACTION BECAUSE TRANSACTION IS TOO LARGE
                    if output.sourceWSOLNewAccount != nil {
                        output.additionalTransaction = try makeTransaction(
                            instructions: [instruction],
                            signers: [owner],
                            blockhash: recentBlockhash,
                            accountCreationFee: minimumTokenAccountBalance
                        )
                    } else {
                        output.instructions.append(instruction)
                        output.accountCreationFee += minimumTokenAccountBalance
                    }
                }
                
                // return the address
                output.userDestinationTokenAccountAddress = associatedAddress
            }
        }
    }
}
