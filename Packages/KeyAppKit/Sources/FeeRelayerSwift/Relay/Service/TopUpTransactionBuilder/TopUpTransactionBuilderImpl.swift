import Foundation
import SolanaSwift
import OrcaSwapSwift

class TopUpTransactionBuilderImpl: TopUpTransactionBuilder {
    
    // MARK: - Properties

    /// Client that interacts with solana rpc client
    private let solanaApiClient: SolanaAPIClient

    /// Swap provider client
    private let orcaSwap: OrcaSwapType
    
    /// Solana account
    private let account: KeyPair
    
    // MARK: - Initializer

    init(solanaApiClient: SolanaAPIClient, orcaSwap: OrcaSwapType, account: KeyPair) {
        self.solanaApiClient = solanaApiClient
        self.orcaSwap = orcaSwap
        self.account = account
    }
    
    /// Build top up transaction from given data
    /// - Parameters:
    ///   - context: Relay context
    ///   - sourceToken: fromToken to top up
    ///   - topUpPools: pools using for top up with swap
    ///   - targetAmount: amount for topping up
    ///   - blockhash: recent blockhash
    /// - Returns: swap data to pass to fee relayer api client and prepared top up transaction
    func buildTopUpTransaction(
        context: RelayContext,
        sourceToken: TokenAccount,
        topUpPools: PoolsPair,
        targetAmount: UInt64,
        blockhash: String
    ) async throws -> (swapData: FeeRelayerRelaySwapType, preparedTransaction: PreparedTransaction) {
        // assertion
        let userSourceTokenAccountAddress = sourceToken.address
        let sourceTokenMintAddress = sourceToken.mint
        let feePayerAddress = context.feePayerAddress
        let associatedTokenAddress = try PublicKey.associatedTokenAddress(
            walletAddress: feePayerAddress,
            tokenMintAddress: sourceTokenMintAddress
        ) ?! FeeRelayerError.unknown
        let network = solanaApiClient.endpoint.network
        
        guard userSourceTokenAccountAddress != associatedTokenAddress else {
            throw FeeRelayerError.unknown
        }
        
        // calculate transaction fee
        var expectedFee = FeeAmount.zero
        let expectedTransactionNetworkFee = 2 * context.lamportsPerSignature // feePayer, owner
        if context.usageStatus.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionNetworkFee) == false {
            expectedFee.transaction += expectedTransactionNetworkFee
        }
        
        // form transaction
        var instructions = [TransactionInstruction]()
        
        // create user relay account
        if context.relayAccountStatus == .notYetCreated {
            instructions.append(
                SystemProgram.transferInstruction(
                    from: feePayerAddress,
                    to: try RelayProgram.getUserRelayAddress(user: account.publicKey, network: network),
                    lamports: context.minimumRelayAccountBalance
                )
            )
            expectedFee.accountBalances += context.minimumRelayAccountBalance
        }
        
        // top up swap
        let transitTokenAccountManager = TransitTokenAccountManagerImpl(
            owner: account.publicKey,
            solanaAPIClient: solanaApiClient,
            orcaSwap: orcaSwap
        )
        
        let transitToken = try transitTokenAccountManager.getTransitToken(
            pools: topUpPools
        )
        
        let needsCreateTransitTokenAccount = try await transitTokenAccountManager.checkIfNeedsCreateTransitTokenAccount(
            transitToken: transitToken
        )
        
        let swap = try await prepareSwapData(
            account: account,
            network: network,
            pools: topUpPools,
            inputAmount: nil,
            minAmountOut: targetAmount,
            slippage: FeeRelayerConstants.topUpSlippage,
            transitTokenMintPubkey: transitToken?.mint,
            needsCreateTransitTokenAccount: needsCreateTransitTokenAccount == true
        )
        let userTransferAuthority = swap.transferAuthorityAccount?.publicKey
        
        switch swap.swapData {
        case let swap as DirectSwapData:
            expectedFee.accountBalances += context.minimumTokenAccountBalance
            // approve
            if let userTransferAuthority = userTransferAuthority {
                instructions.append(
                    TokenProgram.approveInstruction(
                        account: userSourceTokenAccountAddress,
                        delegate: userTransferAuthority,
                        owner: account.publicKey,
                        multiSigners: [],
                        amount: swap.amountIn
                    )
                )
            }
            
            // top up
            instructions.append(
                try RelayProgram.topUpSwapInstruction(
                    network: network,
                    topUpSwap: swap,
                    userAuthorityAddress: account.publicKey,
                    userSourceTokenAccountAddress: userSourceTokenAccountAddress,
                    feePayerAddress: feePayerAddress
                )
            )
        case let swap as TransitiveSwapData:
            // approve
            if let userTransferAuthority = userTransferAuthority {
                instructions.append(
                    TokenProgram.approveInstruction(
                        account: userSourceTokenAccountAddress,
                        delegate: userTransferAuthority,
                        owner: account.publicKey,
                        multiSigners: [],
                        amount: swap.from.amountIn
                    )
                )
            }
            
            // create transit token account
            if needsCreateTransitTokenAccount == true, let transitTokenAccountAddress = transitToken?.address {
                instructions.append(
                    try RelayProgram.createTransitTokenAccountInstruction(
                        feePayer: feePayerAddress,
                        userAuthority: account.publicKey,
                        transitTokenAccount: transitTokenAccountAddress,
                        transitTokenMint: try PublicKey(string: swap.transitTokenMintPubkey),
                        network: network
                    )
                )
            }
            
            // Destination WSOL account funding
            expectedFee.accountBalances += context.minimumTokenAccountBalance
            
            // top up
            instructions.append(
                try RelayProgram.topUpSwapInstruction(
                    network: network,
                    topUpSwap: swap,
                    userAuthorityAddress: account.publicKey,
                    userSourceTokenAccountAddress: userSourceTokenAccountAddress,
                    feePayerAddress: feePayerAddress
                )
            )
        default:
            fatalError("unsupported swap type")
        }
        
        // transfer
        instructions.append(
            try RelayProgram.transferSolInstruction(
                userAuthorityAddress: account.publicKey,
                recipient: feePayerAddress,
                lamports: expectedFee.total,
                network: network
            )
        )
        
        var transaction = Transaction()
        transaction.instructions = instructions
        transaction.feePayer = feePayerAddress
        transaction.recentBlockhash = blockhash
        
        // resign transaction
        var signers = [account]
        if let tranferAuthority = swap.transferAuthorityAccount {
            signers.append(tranferAuthority)
        }
        try transaction.sign(signers: signers)
        
       if let decodedTransaction = transaction.jsonString {
           print(decodedTransaction)
       }
        
        return (
            swapData: swap.swapData,
            preparedTransaction: .init(
                transaction: transaction,
                signers: signers,
                expectedFee: expectedFee
            )
        )
    }
    
    /// Prepare swap data from swap pools
    func prepareSwapData(
        account: KeyPair,
        network: Network,
        pools: PoolsPair,
        inputAmount: UInt64?,
        minAmountOut: UInt64?,
        slippage: Double,
        transitTokenMintPubkey: PublicKey? = nil,
        newTransferAuthority: Bool = false,
        needsCreateTransitTokenAccount: Bool
    ) async throws -> (swapData: FeeRelayerRelaySwapType, transferAuthorityAccount: KeyPair?) {
        // preconditions
        guard pools.count > 0 && pools.count <= 2 else { throw FeeRelayerError.swapPoolsNotFound }
        guard !(inputAmount == nil && minAmountOut == nil) else { throw FeeRelayerError.invalidAmount }
        
        // create transferAuthority
        let transferAuthority = try await KeyPair(network: network)
        
        // form topUp params
        if pools.count == 1 {
            let pool = pools[0]
            
            guard let amountIn = try inputAmount ?? pool.getInputAmount(minimumReceiveAmount: minAmountOut!, slippage: slippage),
                  let minAmountOut = try minAmountOut ?? pool.getMinimumAmountOut(inputAmount: inputAmount!, slippage: slippage)
            else { throw FeeRelayerError.invalidAmount }
            
            let directSwapData = pool.getSwapData(
                transferAuthorityPubkey: newTransferAuthority ? transferAuthority.publicKey: account.publicKey,
                amountIn: amountIn,
                minAmountOut: minAmountOut
            )
            return (swapData: directSwapData, transferAuthorityAccount: newTransferAuthority ? transferAuthority: nil)
        } else {
            let firstPool = pools[0]
            let secondPool = pools[1]
            
            guard let transitTokenMintPubkey = transitTokenMintPubkey else {
                throw FeeRelayerError.transitTokenMintNotFound
            }
            
            // if input amount is provided
            var firstPoolAmountIn = inputAmount
            var secondPoolAmountIn: UInt64?
            var secondPoolAmountOut = minAmountOut
            
            if let inputAmount = inputAmount {
                secondPoolAmountIn = try firstPool.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage) ?? 0
                secondPoolAmountOut = try secondPool.getMinimumAmountOut(inputAmount: secondPoolAmountIn!, slippage: slippage)
            } else if let minAmountOut = minAmountOut {
                secondPoolAmountIn = try secondPool.getInputAmount(minimumReceiveAmount: minAmountOut, slippage: slippage) ?? 0
                firstPoolAmountIn = try firstPool.getInputAmount(minimumReceiveAmount: secondPoolAmountIn!, slippage: slippage)
            }
            
            guard let firstPoolAmountIn = firstPoolAmountIn,
                  let secondPoolAmountIn = secondPoolAmountIn,
                  let secondPoolAmountOut = secondPoolAmountOut
            else {
                throw FeeRelayerError.invalidAmount
            }
            
            let transitiveSwapData = TransitiveSwapData(
                from: firstPool.getSwapData(
                    transferAuthorityPubkey: newTransferAuthority ? transferAuthority.publicKey: account.publicKey,
                    amountIn: firstPoolAmountIn,
                    minAmountOut: secondPoolAmountIn
                ),
                to: secondPool.getSwapData(
                    transferAuthorityPubkey: newTransferAuthority ? transferAuthority.publicKey: account.publicKey,
                    amountIn: secondPoolAmountIn,
                    minAmountOut: secondPoolAmountOut
                ),
                transitTokenMintPubkey: transitTokenMintPubkey.base58EncodedString,
                needsCreateTransitTokenAccount: needsCreateTransitTokenAccount
            )
            return (swapData: transitiveSwapData, transferAuthorityAccount: newTransferAuthority ? transferAuthority: nil)
        }
    }
}
