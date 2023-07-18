//
//  File.swift
//  
//
//  Created by Chung Tran on 06/05/2022.
//

import Foundation
import SolanaSwift

public class OrcaSwap: OrcaSwapType {
    // MARK: - Properties
    private var cache: SwapInfo?
    let apiClient: OrcaSwapAPIClient
    let blockchainClient: SolanaBlockchainClient
    let solanaClient: SolanaAPIClient
    let accountStorage: SolanaAccountStorage
    
    var info: SwapInfo?
    let balancesCache = BalancesCache()
    let locker = NSLock()
    
    // MARK: - Initializer
    public init(
        apiClient: OrcaSwapAPIClient,
        solanaClient: SolanaAPIClient,
        blockchainClient: SolanaBlockchainClient,
        accountStorage: SolanaAccountStorage
    ) {
        self.apiClient = apiClient
        self.solanaClient = solanaClient
        self.blockchainClient = blockchainClient
        self.accountStorage = accountStorage
    }
    
    // MARK: - Methods
    /// Prepare all needed infos for swapping
    public func load() async throws {
        // already been loaded
        if info != nil { return }
        
        // load
        let (tokens, pools, programId) = try await (
            apiClient.getTokens(),
            apiClient.getPools(),
            apiClient.getProgramID()
        )
        
        // find all available routes
        let routes = findAllAvailableRoutes(tokens: tokens, pools: pools)
        let tokenNames = tokens.reduce([String: String]()) { result, token in
            var result = result
            result[token.value.mint] = token.key
            return result
        }
        
        // create swap info
        let swapInfo = SwapInfo(
            routes: routes,
            tokens: tokens,
            pools: pools,
            programIds: programId,
            tokenNames: tokenNames
        )
        
        // save cache
        locker.lock()
        info = swapInfo
        locker.unlock()
    }
    
    /// Get token's mint address by its name
    public func getMint(tokenName: String) -> String? {
        info?.tokenNames.first(where: {$0.value == tokenName})?.key
    }
    
    /// Find posible destination tokens by mint
    /// - Parameter fromMint: from token mint
    /// - Returns: List of token mints that can be swapped to
    public func findPosibleDestinationMints(
        fromMint: String
    ) throws -> [String] {
        guard let fromTokenName = getTokenFromMint(fromMint)?.name
        else {throw OrcaSwapError.notFound}
        
        let routes = try findRoutes(fromTokenName: fromTokenName, toTokenName: nil)
        return routes.keys
            .compactMap {
                $0.components(separatedBy: "/")
                    .first(where: {$0 != fromTokenName})
            }
            .unique
            .compactMap {info?.tokens[$0]?.mint}
    }
    
    /// Get all tradable pools pairs for current token pair
    /// - Returns: route and parsed pools
    public func getTradablePoolsPairs(
        fromMint: String,
        toMint: String
    ) async throws -> [PoolsPair] {
        // assertion
        guard let fromTokenName = getTokenFromMint(fromMint)?.name,
              let toTokenName = getTokenFromMint(toMint)?.name,
              let currentRoutes = try? findRoutes(fromTokenName: fromTokenName, toTokenName: toTokenName)
                .first?.value
        else { return [] }
        
        // retrieve all routes
        var poolsPairs = [PoolsPair]()
        try Task.checkCancellation()
        try await withThrowingTaskGroup(of: [Pool]?.self) {group in
            for route in currentRoutes where route.count <= 2 {
                group.addTask { [weak self] in
                    guard let self = self else {return nil}
                    try Task.checkCancellation()
                    return try await self.getPools(
                        forRoute: route,
                        fromTokenName: fromTokenName,
                        toTokenName: toTokenName
                    )
                }
            }
            
            for try await pools in group {
                try Task.checkCancellation()
                guard let pools = pools else {continue}
                poolsPairs.append(pools)
            }
        }
        
        return poolsPairs
    }
    
    /// Find best pool to swap from input amount
    public func findBestPoolsPairForInputAmount(
        _ inputAmount: UInt64,
        from poolsPairs: [PoolsPair],
        prefersDirectSwap: Bool
    ) throws -> PoolsPair? {
        var poolsPairs = poolsPairs
//
//        // filter out deprecated pools
//        let indeprecatedPools = poolsPairs.filter {!$0.contains(where: {$0.deprecated == true})}
//        if indeprecatedPools.count > 0 {
//            poolsPairs = indeprecatedPools
//        }
        
        guard poolsPairs.count > 0 else {return nil}
        
        // sort
        poolsPairs.sort { pair1, pair2 in
            let estimatedAmount1 = pair1.getOutputAmount(fromInputAmount: inputAmount) ?? 0
            let estimatedAmount2 = pair2.getOutputAmount(fromInputAmount: inputAmount) ?? 0
            
            return estimatedAmount1 > estimatedAmount2
        }
        
        poolsPairs = poolsPairs.filter {
            !$0.isEmpty &&
            $0.count <= 2 &&
            $0.getOutputAmount(fromInputAmount: inputAmount) ?? 0 > 0
        }
        
        // TODO: - Think about better solution!
        // For some case when swaping small amount (how small?) which involved BTC or ETH
        // For example: USDC -> wstETH -> stSOL
        // The transaction might be rejected because the input amount and output amount of intermediary token (wstETH) is too small
        // To temporarily fix this issue, prefers direct route or transitive route without ETH, BTC
        var bestDirectPoolsPair: PoolsPair?
        if prefersDirectSwap {
            bestDirectPoolsPair = poolsPairs.first(where: {$0.count == 1})
        }
        
        return bestDirectPoolsPair ?? poolsPairs.first
    }
    
    /// Find best pool to swap from estimated amount
    public func findBestPoolsPairForEstimatedAmount(
        _ estimatedAmount: UInt64,
        from poolsPairs: [PoolsPair],
        prefersDirectSwap: Bool
    ) throws -> PoolsPair? {
        var poolsPairs = poolsPairs
//
//        // filter out deprecated pools
//        let indeprecatedPools = poolsPairs.filter {!$0.contains(where: {$0.deprecated == true})}
//        if indeprecatedPools.count > 0 {
//            poolsPairs = indeprecatedPools
//        }
        
        // sort
        poolsPairs.sort { pair1, pair2 in
            let inputAmount1 = pair1.getInputAmount(fromEstimatedAmount: estimatedAmount) ?? 0
            let inputAmount2 = pair2.getInputAmount(fromEstimatedAmount: estimatedAmount) ?? 0
            
            return inputAmount1 < inputAmount2
        }
        
        poolsPairs = poolsPairs.filter {
            !$0.isEmpty &&
            $0.count <= 2 &&
            $0.getInputAmount(fromEstimatedAmount: estimatedAmount) ?? 0 > 0
        }
        
        // TODO: - Think about better solution!
        // For some case when swaping small amount (how small?) which involved BTC or ETH
        // For example: USDC -> wstETH -> stSOL
        // The transaction might be rejected because the input amount and output amount of intermediary token (wstETH) is too small
        // To temporarily fix this issue, prefers direct route
        var bestDirectPoolsPair: PoolsPair?
        if prefersDirectSwap {
            bestDirectPoolsPair = poolsPairs.first(where: {$0.count == 1})
        }
        
        return bestDirectPoolsPair ?? poolsPairs.first
    }
    
    /// Get liquidity provider fee
    public func getLiquidityProviderFee(
        bestPoolsPair: PoolsPair?,
        inputAmount: Double?,
        slippage: Double
    ) throws -> [UInt64] {
        try bestPoolsPair?.calculateLiquidityProviderFees(inputAmount: inputAmount ?? 0, slippage: slippage) ?? []
    }
    
    /// Get network fees from current context
    /// - Returns: transactions fees (fees for signatures), liquidity provider fees (fees in intermediary token?, fees in destination token)
    public func getNetworkFees(
        myWalletsMints: [String],
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: PoolsPair?,
        inputAmount: Double?,
        slippage: Double,
        lamportsPerSignature: UInt64,
        minRentExempt: UInt64
    ) async throws -> FeeAmount {
        guard let owner = accountStorage.account?.publicKey else {throw OrcaSwapError.unauthorized}
        
        let numberOfPools = UInt64(bestPoolsPair?.count ?? 0)
        var numberOfTransactions: UInt64 = 1
        
        if numberOfPools == 2 {
            let myTokens = myWalletsMints.compactMap {getTokenFromMint($0)}.map {$0.name}
            let intermediaryTokenName = bestPoolsPair![0].tokenBName
            
            if !myTokens.contains(intermediaryTokenName) ||
                toWalletPubkey == nil
            {
                numberOfTransactions += 1
            }
        }
        
        var expectedFee = FeeAmount.zero

        // fee for owner's signature
        expectedFee.transaction += numberOfTransactions * lamportsPerSignature

        // when source token is native SOL
        if fromWalletPubkey == owner.base58EncodedString {
            // WSOL's signature
            expectedFee.transaction += lamportsPerSignature
            expectedFee.deposit += minRentExempt
        }
        
        // when there is intermediary token
        var isIntermediaryTokenCreated = true
        if numberOfPools == 2,
           let decimals = bestPoolsPair![0].tokenABalance?.decimals,
           let inputAmount = inputAmount,
           let intermediaryToken = bestPoolsPair?
                .getIntermediaryToken(
                    inputAmount: inputAmount.toLamport(decimals: decimals),
                    slippage: slippage
                ),
           let mint = getMint(tokenName: intermediaryToken.tokenName)
        {
            // when intermediary token is SOL, a deposit fee for creating WSOL is needed (will be returned after transaction)
            if intermediaryToken.tokenName == "SOL" {
                expectedFee.transaction += lamportsPerSignature
                expectedFee.deposit += minRentExempt
            }
            
            // Check if intermediary token creation is needed
            else {
                isIntermediaryTokenCreated = try await solanaClient
                    .checkIfAssociatedTokenAccountExists(owner: owner, mint: mint)
            }
        }
        
        // when needed to create destination
        if toWalletPubkey == nil {
            expectedFee.accountBalances += minRentExempt
        }

        // when destination is native SOL
        else if toWalletPubkey == owner.base58EncodedString {
            expectedFee.transaction += lamportsPerSignature
            expectedFee.deposit += minRentExempt
        }
        
        // add aditional fee if intermediary token is NOT yet created
        if !isIntermediaryTokenCreated {
            expectedFee.accountBalances += minRentExempt
        }
        
        return expectedFee
    }
    
    /// Execute swap
    public func prepareForSwapping(
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: PoolsPair,
        amount: Double,
        feePayer: PublicKey?,
        slippage: Double
    ) async throws -> ([PreparedSwapTransaction], String? /*New created account*/) {
        guard bestPoolsPair.count > 0 else {
            throw OrcaSwapError.swapInfoMissing
        }
        guard let fromDecimals = bestPoolsPair[0].tokenABalance?.decimals else {
            throw OrcaSwapError.invalidPool
        }
        
        let amount = amount.toLamport(decimals: fromDecimals)
        
        let minRenExemption = try await solanaClient.getMinimumBalanceForRentExemption(span: 165)
        
        if bestPoolsPair.count == 1 {
            let directSwap = try await directSwap(
                pool: bestPoolsPair[0],
                fromTokenPubkey: fromWalletPubkey,
                toTokenPubkey: toWalletPubkey,
                amount: amount,
                feePayer: feePayer,
                slippage: slippage,
                minRenExemption: minRenExemption
            )
            return ([directSwap.0], directSwap.1)
        } else {
            let pool0 = bestPoolsPair[0]
            let pool1 = bestPoolsPair[1]
            
            // TO AVOID `TRANSACTION IS TOO LARGE` ERROR, WE SPLIT OPERATION INTO 2 TRANSACTIONS
            // FIRST TRANSACTION IS TO CREATE ASSOCIATED TOKEN ADDRESS FOR INTERMEDIARY TOKEN OR DESTINATION TOKEN (IF NOT YET CREATED) AND WAIT FOR CONFIRMATION **IF THEY ARE NOT WSOL**
            // SECOND TRANSACTION TAKE THE RESULT OF FIRST TRANSACTION (ADDRESSES) TO REDUCE ITS SIZE. **IF INTERMEDIATE TOKEN OR DESTINATION TOKEN IS WSOL, IT SHOULD BE INCLUDED IN THIS TRANSACTION**
            
            // First transaction
            let (intermediaryTokenAddress, destinationTokenAddress, wsolAccountInstructions, preparedTransaction) = try await createIntermediaryTokenAndDestinationTokenAddressIfNeeded(
                pool0: pool0,
                pool1: pool1,
                toWalletPubkey: toWalletPubkey,
                feePayer: feePayer,
                minRenExemption: minRenExemption
            )
            
            let (transaction, newAccount) = try await transitiveSwap(
                pool0: pool0,
                pool1: pool1,
                fromTokenPubkey: fromWalletPubkey,
                intermediaryTokenAddress: intermediaryTokenAddress.base58EncodedString,
                destinationTokenAddress: destinationTokenAddress.base58EncodedString,
                feePayer: feePayer,
                wsolAccountInstructions: wsolAccountInstructions,
                isDestinationNew: toWalletPubkey == nil,
                amount: amount,
                slippage: slippage,
                minRenExemption: minRenExemption
            )
            
            var transactions = [PreparedSwapTransaction]()
            if let preparedTransaction = preparedTransaction {
                transactions.append(preparedTransaction)
            }
            transactions.append(transaction)
            return (transactions, newAccount)
        }
    }
    
    /// Prepare for swapping and swap
    public func swap(
        fromWalletPubkey: String,
        toWalletPubkey: String?,
        bestPoolsPair: PoolsPair,
        amount: Double,
        slippage: Double,
        isSimulation: Bool
    ) async throws -> SwapResponse {
        guard let owner = accountStorage.account?.publicKey else {throw OrcaSwapError.unauthorized}
        
        let (swapTransactions, newAccount) = try await prepareForSwapping(
            fromWalletPubkey: fromWalletPubkey,
            toWalletPubkey: toWalletPubkey,
            bestPoolsPair: bestPoolsPair,
            amount: amount,
            feePayer: nil,
            slippage: slippage
        )
        
        guard swapTransactions.count > 0 && swapTransactions.count <= 2 else {
            throw OrcaSwapError.invalidNumberOfTransactions
        }
        
        let txid = try await prepareAndSend(
            swapTransactions[0],
            feePayer: owner,
            isSimulation: swapTransactions.count == 2 ? false: isSimulation // the first transaction in transitive swap must be non-simulation
        )
        
        if swapTransactions.count <= 1 {
            return .init(transactionId: txid, newWalletPubkey: newAccount)
        }
        
        else {
            // wait maximum 60s to make sure that signature is confirmed
            try await solanaClient.waitForConfirmation(signature: txid, ignoreStatus: true)
            
            // send second transaction anyway
            let txid2 = try await Task.retrying(
                where: { error in
                    if let error = error as? SolanaError {
                        switch error {
                        case .transactionError(_, logs: let logs) where logs.contains("Program log: Error: InvalidAccountData"):
                            return true
                        default:
                            break
                        }
                    }
                    
                    if let error = error as? SolanaSwift.APIClientError {
                        switch error {
                        case .responseError(let error) where error.data?.logs?.contains("Program log: Error: InvalidAccountData") == true:
                            return true
                        default:
                            break
                        }
                    }
                    
                    return false
                },
                maxRetryCount: .max,
                retryDelay: 1,
                timeoutInSeconds: 60
            ) {
                try await self.prepareAndSend(
                    swapTransactions[1],
                    feePayer: owner,
                    isSimulation: isSimulation
                )
            }
                .value
            
            return .init(transactionId: txid2, newWalletPubkey: newAccount)
        }
    }
    
    func prepareAndSend(
        _ swapTransaction: PreparedSwapTransaction,
        feePayer: PublicKey,
        isSimulation: Bool
    ) async throws -> String {
        let preparedTransaction = try await blockchainClient.prepareTransaction(
            instructions: swapTransaction.instructions,
            signers: swapTransaction.signers,
            feePayer: feePayer,
            feeCalculator: nil
        )
        
        if isSimulation {
            let _ = try await blockchainClient.simulateTransaction(preparedTransaction: preparedTransaction)
            return ""
        }
        
        return try await blockchainClient.sendTransaction(preparedTransaction: preparedTransaction)
    }
    
    /// Find routes for from and to token name, aka symbol
    func findRoutes(
        fromTokenName: String?,
        toTokenName: String?
    ) throws -> Routes {
        guard let info = info else { throw OrcaSwapError.swapInfoMissing }
        
        // if fromToken isn't selected
        guard let fromTokenName = fromTokenName else {return [:]}

        // if toToken isn't selected
        guard let toTokenName = toTokenName else {
            // get all routes that have token A
            let routes = info.routes.filter {$0.key.components(separatedBy: "/").contains(fromTokenName)}
                .filter {!$0.value.isEmpty}
            return routes
        }

        // get routes with fromToken and toToken
        let pair = [fromTokenName, toTokenName]
        let validRoutesNames = [
            pair.joined(separator: "/"),
            pair.reversed().joined(separator: "/")
        ]
        return info.routes.filter {validRoutesNames.contains($0.key)}
            .filter {!$0.value.isEmpty}
    }
    
    /// Map mint to token info
    private func getTokenFromMint(_ mint: String) -> (name: String, info: TokenValue)? {
        let tokenInfo = info?.tokens.first(where: {$0.value.mint == mint})
        guard let name = tokenInfo?.key, let value = tokenInfo?.value else {return nil}
        return (name: name, info: value)
    }
    
    private func directSwap(
        pool: Pool,
        fromTokenPubkey: String,
        toTokenPubkey: String?,
        amount: UInt64,
        feePayer: PublicKey?,
        slippage: Double,
        minRenExemption: Lamports
    ) async throws -> (PreparedSwapTransaction, String?) {
        guard let owner = accountStorage.account else { throw OrcaSwapError.unauthorized }
        guard let info = info else { throw OrcaSwapError.swapInfoMissing }
        
        let (accountInstructions, accountCreationFee) = try await [pool].constructExchange(
            tokens: info.tokens,
            blockchainClient: blockchainClient,
            owner: owner.publicKey,
            fromTokenPubkey: fromTokenPubkey,
            toTokenPubkey: toTokenPubkey,
            amount: amount,
            slippage: slippage,
            feePayer: feePayer,
            minRenExemption: minRenExemption
        )
        
        return (
            .init(
                instructions: accountInstructions.instructions + accountInstructions.cleanupInstructions,
                signers: [owner] + accountInstructions.signers,
                accountCreationFee: accountCreationFee
            ),
            toTokenPubkey == nil ? accountInstructions.account.base58EncodedString: nil
        )
    }
    
    private func transitiveSwap(
        pool0: Pool,
        pool1: Pool,
        fromTokenPubkey: String,
        intermediaryTokenAddress: String,
        destinationTokenAddress: String,
        feePayer: PublicKey?,
        wsolAccountInstructions: AccountInstructions?,
        isDestinationNew: Bool,
        amount: UInt64,
        slippage: Double,
        minRenExemption: Lamports
    ) async throws -> (PreparedSwapTransaction, String?) {
        guard let owner = accountStorage.account else { throw OrcaSwapError.unauthorized }
        guard let info = info else { throw OrcaSwapError.swapInfoMissing }
        
        var (accountInstructions, accountCreationFee) = try await [pool0, pool1].constructExchange(
            tokens: info.tokens,
            blockchainClient: blockchainClient,
            owner: owner.publicKey,
            fromTokenPubkey: fromTokenPubkey,
            intermediaryTokenAddress: intermediaryTokenAddress,
            toTokenPubkey: destinationTokenAddress,
            amount: amount,
            slippage: slippage,
            feePayer: feePayer,
            minRenExemption: minRenExemption
        )
        
        var instructions = accountInstructions.instructions + accountInstructions.cleanupInstructions
        var additionalSigners = [KeyPair]()
        if let wsolAccountInstructions = wsolAccountInstructions {
            additionalSigners.append(contentsOf: wsolAccountInstructions.signers)
            instructions.insert(contentsOf: wsolAccountInstructions.instructions, at: 0)
            instructions.append(contentsOf: wsolAccountInstructions.cleanupInstructions)
            accountCreationFee += minRenExemption
        }
        
        return (
            .init(
                instructions: instructions,
                signers: [owner] + additionalSigners + accountInstructions.signers,
                accountCreationFee: accountCreationFee
            ),
            isDestinationNew ? accountInstructions.account.base58EncodedString: nil
        )
    }
    
    private func createIntermediaryTokenAndDestinationTokenAddressIfNeeded(
        pool0: Pool,
        pool1: Pool,
        toWalletPubkey: String?,
        feePayer: PublicKey?,
        minRenExemption: Lamports
    ) async throws -> (PublicKey, PublicKey, AccountInstructions?, PreparedSwapTransaction?) /*intermediaryTokenAddress, destination token address, WSOL account and instructions, account creation fee*/ {
        
        guard let owner = accountStorage.account,
              let intermediaryTokenMint = try? info?.tokens[pool0.tokenBName]?.mint.toPublicKey(),
              let destinationMint = try? info?.tokens[pool1.tokenBName]?.mint.toPublicKey()
        else { throw OrcaSwapError.unauthorized }
        
        let createIntermediaryTokenAccountInstructions: AccountInstructions
        let createDestinationTokenAccountInstructions: AccountInstructions
        
        async let createDestinationTokenAccountInstructionsRequest = blockchainClient
            .prepareForCreatingAssociatedTokenAccount(
                owner: owner.publicKey,
                mint: destinationMint,
                feePayer: feePayer ?? owner.publicKey,
                closeAfterward: false
            )
        
        if intermediaryTokenMint == .wrappedSOLMint {
            (createIntermediaryTokenAccountInstructions, createDestinationTokenAccountInstructions) = try await (
                blockchainClient.prepareCreatingWSOLAccountAndCloseWhenDone(
                    from: owner.publicKey,
                    amount: 0,
                    payer: feePayer ?? owner.publicKey,
                    minRentExemption: nil
                ),
                createDestinationTokenAccountInstructionsRequest
            )
        } else {
            
            (createIntermediaryTokenAccountInstructions, createDestinationTokenAccountInstructions) = try await (
                blockchainClient.prepareForCreatingAssociatedTokenAccount(
                    owner: owner.publicKey,
                    mint: intermediaryTokenMint,
                    feePayer: feePayer ?? owner.publicKey,
                    closeAfterward: true
                ),
                createDestinationTokenAccountInstructionsRequest
            )
        }
        
        // get all creating instructions, PASS WSOL ACCOUNT INSTRUCTIONS TO THE SECOND TRANSACTION
        var instructions = [TransactionInstruction]()
        var wsolAccountInstructions: AccountInstructions?
        var accountCreationFee: UInt64 = 0
        
        if intermediaryTokenMint == .wrappedSOLMint {
            wsolAccountInstructions = createIntermediaryTokenAccountInstructions
            wsolAccountInstructions?.cleanupInstructions = []
        } else {
            instructions.append(contentsOf: createIntermediaryTokenAccountInstructions.instructions)
            if !createIntermediaryTokenAccountInstructions.instructions.isEmpty {
                accountCreationFee += minRenExemption
            }
            // omit clean up instructions
        }
        if destinationMint == .wrappedSOLMint {
            wsolAccountInstructions = createDestinationTokenAccountInstructions
        } else {
            instructions.append(contentsOf: createDestinationTokenAccountInstructions.instructions)
            if !createDestinationTokenAccountInstructions.instructions.isEmpty {
                accountCreationFee += minRenExemption
            }
        }
        
        // if token address has already been created, then no need to send any transactions
        if instructions.isEmpty {
            return (
                createIntermediaryTokenAccountInstructions.account,
                createDestinationTokenAccountInstructions.account,
                wsolAccountInstructions,
                nil
            )
        }
        
        // if creating transaction is needed
        else {
            return (
                createIntermediaryTokenAccountInstructions.account,
                createDestinationTokenAccountInstructions.account,
                wsolAccountInstructions,
                .init(
                    instructions: instructions,
                    signers: [owner],
                    accountCreationFee: accountCreationFee
                )
            )
        }
    }
}

// MARK: - Helpers
private func findAllAvailableRoutes(tokens: [String: TokenValue], pools: Pools) -> Routes {
    let tokens = tokens.filter {$0.value.poolToken != true}
        .map {$0.key}
    let pairs = getPairs(tokens: tokens)
    return getAllRoutes(pairs: pairs, pools: pools)
}

private func getPairs(tokens: [String]) -> [[String]] {
    var pairs = [[String]]()
    
    guard tokens.count > 0 else {return pairs}
    
    for i in 0..<tokens.count-1 {
        for j in i+1..<tokens.count {
            let tokenA = tokens[i]
            let tokenB = tokens[j]
            
            pairs.append(orderTokenPair(tokenA, tokenB))
        }
    }
    
    return pairs
}

private func orderTokenPair(_ tokenX: String, _ tokenY: String) -> [String] {
    if (tokenX == "USDC" && tokenY == "USDT") {
        return [tokenX, tokenY];
    } else if (tokenY == "USDC" && tokenX == "USDT") {
        return [tokenY, tokenX];
    } else if (tokenY == "USDC" || tokenY == "USDT") {
        return [tokenX, tokenY];
    } else if (tokenX == "USDC" || tokenX == "USDT") {
        return [tokenY, tokenX];
    } else if tokenX < tokenY {
        return [tokenX, tokenY];
    } else {
        return [tokenY, tokenX];
    }
}

private func getAllRoutes(pairs: [[String]], pools: Pools) -> Routes {
    var routes: Routes = [:]
    pairs.forEach { pair in
        guard let tokenA = pair.first,
              let tokenB = pair.last
        else {return}
        routes[getTradeId(tokenA, tokenB)] = getRoutes(tokenA: tokenA, tokenB: tokenB, pools: pools)
    }
    return routes
}

private func getTradeId(_ tokenX: String, _ tokenY: String) -> String {
    orderTokenPair(tokenX, tokenY).joined(separator: "/")
}

private func getRoutes(tokenA: String, tokenB: String, pools: Pools) -> [Route] {
    var routes = [Route]()
    
    // Find all pools that contain the same tokens.
    // Checking tokenAName and tokenBName will find Stable pools.
    for (poolId, poolConfig) in pools {
        if (poolConfig.tokenAName == tokenA && poolConfig.tokenBName == tokenB) ||
            (poolConfig.tokenAName == tokenB && poolConfig.tokenBName == tokenA)
        {
            routes.append([poolId])
        }
    }
    
    // Find all pools that contain the first token but not the second
    let firstLegPools = pools
        .filter {
            ($0.value.tokenAName == tokenA && $0.value.tokenBName != tokenB) ||
            ($0.value.tokenBName == tokenA && $0.value.tokenAName != tokenB)
        }
        .reduce([String: String]()) { result, pool in
            var result = result
            result[pool.key] = pool.value.tokenBName == tokenA ? pool.value.tokenAName: pool.value.tokenBName
            return result
        }
    
    // Find all routes that can include firstLegPool and a second pool.
    firstLegPools.forEach { firstLegPoolId, intermediateTokenName in
        pools.forEach { secondLegPoolId, poolConfig in
            if (poolConfig.tokenAName == intermediateTokenName && poolConfig.tokenBName == tokenB) ||
                (poolConfig.tokenBName == intermediateTokenName && poolConfig.tokenAName == tokenB)
            {
                routes.append([firstLegPoolId, secondLegPoolId])
            }
        }
    }
    
    return routes
}

