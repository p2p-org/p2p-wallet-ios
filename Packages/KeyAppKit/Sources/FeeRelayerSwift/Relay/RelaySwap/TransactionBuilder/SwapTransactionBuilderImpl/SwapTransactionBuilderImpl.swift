import Foundation
import OrcaSwapSwift
import SolanaSwift

public class SwapTransactionBuilderImpl : SwapTransactionBuilder {
    
    let network: Network
    let transitTokenAccountManager: TransitTokenAccountManager
    let destinationAnalysator: DestinationAnalysator
    let feePayerAddress: PublicKey
    let minimumTokenAccountBalance: UInt64
    let lamportsPerSignature: UInt64
    
    public init(
        network: Network,
        transitTokenAccountManager: TransitTokenAccountManager,
        destinationAnalysator: DestinationAnalysator,
        feePayerAddress: PublicKey,
        minimumTokenAccountBalance: UInt64,
        lamportsPerSignature: UInt64
    ) {
        self.network = network
        self.transitTokenAccountManager = transitTokenAccountManager
        self.destinationAnalysator = destinationAnalysator
        self.feePayerAddress = feePayerAddress
        self.minimumTokenAccountBalance = minimumTokenAccountBalance
        self.lamportsPerSignature = lamportsPerSignature
    }
    
    public func buildSwapTransaction(
        userAccount: KeyPair,
        pools: PoolsPair,
        inputAmount: UInt64,
        slippage: Double,
        sourceTokenAccount: TokenAccount,
        destinationTokenMint: PublicKey,
        destinationTokenAddress: PublicKey?,
        blockhash: String
    ) async throws -> (transactions: [PreparedTransaction], additionalPaybackFee: UInt64) {
        // form output
        var output = SwapTransactionBuilderOutput()
        output.userSource = sourceTokenAccount.address
        
        // assert userSource
        let associatedToken = try PublicKey.associatedTokenAddress(
            walletAddress: feePayerAddress,
            tokenMintAddress: sourceTokenAccount.mint
        )
        guard output.userSource != associatedToken else { throw FeeRelayerError.wrongAddress }
        
        // check transit token
        try await checkTransitTokenAccount(
            owner: userAccount.publicKey,
            poolsPair: pools,
            output: &output
        )
        
        // check source
        try await checkSource(
            owner: userAccount.publicKey,
            sourceMint: sourceTokenAccount.mint,
            inputAmount: inputAmount,
            output: &output
        )
        
        // check destination
        try await checkDestination(
            owner: userAccount,
            destinationMint: destinationTokenMint,
            destinationAddress: destinationTokenAddress,
            recentBlockhash: blockhash,
            output: &output
        )
        
        // build swap data
        let swapData = try await buildSwapData(
            userAccount: userAccount,
            pools: pools,
            inputAmount: inputAmount,
            minAmountOut: nil,
            slippage: slippage,
            transitTokenMintPubkey: output.transitTokenMintPubkey,
            needsCreateTransitTokenAccount: output.needsCreateTransitTokenAccount == true
        )
        
        // check swap data
        try checkSwapData(
            owner: userAccount.publicKey,
            poolsPair: pools,
            env: &output,
            swapData: swapData
        )
        
        // closing accounts
        try checkClosingAccount(
            owner: userAccount.publicKey,
            feePayer: feePayerAddress,
            destinationTokenMint: destinationTokenMint,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            env: &output
        )
        
        // check signers
        checkSigners(
            ownerAccount: userAccount,
            env: &output
        )
        
        var transactions: [PreparedTransaction] = []
        
        // include additional transaciton
        if let additionalTransaction = output.additionalTransaction { transactions.append(additionalTransaction) }
        
        // make primary transaction
        transactions.append(
            try makeTransaction(
                instructions: output.instructions,
                signers: output.signers,
                blockhash: blockhash,
                accountCreationFee: output.accountCreationFee
            )
        )
        
        return (transactions: transactions, additionalPaybackFee: output.additionalPaybackFee)
        
//        fatalError()
    }
    
    func makeTransaction(
        instructions: [TransactionInstruction],
        signers: [KeyPair],
        blockhash: String,
        accountCreationFee: UInt64
    ) throws -> PreparedTransaction {
        var transaction = Transaction()
        transaction.instructions = instructions
        transaction.recentBlockhash = blockhash
        transaction.feePayer = feePayerAddress
    
        try transaction.sign(signers: signers)
        
        // calculate fee first
        let expectedFee = FeeAmount(
            transaction: try transaction.calculateTransactionFee(lamportsPerSignatures: lamportsPerSignature),
            accountBalances: accountCreationFee
        )
        
        return .init(transaction: transaction, signers: signers, expectedFee: expectedFee)
    }
}
