//
//  File.swift
//  
//
//  Created by Chung Tran on 20/10/2021.
//

import Foundation
import SolanaSwift

private let N_COINS: UInt64 = 2
private let N_COINS_SQUARED: UInt64 = 4
private let STABLE = "Stable"
private let CONSTANT_PRODUCT = "ConstantProduct"

public struct Pool: Codable, Equatable {
    public let account: String
    public let authority: String
    let nonce: UInt64
    public let poolTokenMint: String
    public var tokenAccountA: String
    public var tokenAccountB: String
    public let feeAccount: String
    let hostFeeAccount: String?
    let feeNumerator: UInt64
    let feeDenominator: UInt64
    let ownerTradeFeeNumerator: UInt64
    let ownerTradeFeeDenominator: UInt64
    let ownerWithdrawFeeNumerator: UInt64
    let ownerWithdrawFeeDenominator: UInt64
    let hostFeeNumerator: UInt64
    let hostFeeDenominator: UInt64
    public internal(set) var tokenAName: String
    public internal(set) var tokenBName: String
    let curveType: String
    let amp: UInt64?
    let programVersion: UInt64?
    public let deprecated: Bool?
    
    // balance (lazy load)
    var tokenABalance: TokenAccountBalance?
    var tokenBBalance: TokenAccountBalance?
    
    var isStable: Bool?
    
    var reversed: Pool {
        var reversedPool = self
        Swift.swap(&reversedPool.tokenAccountA, &reversedPool.tokenAccountB)
        Swift.swap(&reversedPool.tokenAName, &reversedPool.tokenBName)
        Swift.swap(&reversedPool.tokenABalance, &reversedPool.tokenBBalance)
        return reversedPool
    }
    
    public func getTokenBDecimals() -> Decimals? {
        tokenBBalance?.decimals
    }
    
    public func getTokenADecimals() -> Decimals? {
        tokenABalance?.decimals
    }
    
    public var swapProgramId: PublicKey {
        .orcaSwapId(version: programVersion == 2 ? 2: 1)
    }
}

extension Pool {
    // MARK: - Public methods
    public func getMinimumAmountOut(
        inputAmount: UInt64,
        slippage: Double
    ) throws -> UInt64? {
        let estimatedOutputAmount = try getOutputAmount(fromInputAmount: inputAmount)
        return UInt64(Float64(estimatedOutputAmount) * Float64(1 - slippage))
    }
    
    public func getInputAmount(
        minimumReceiveAmount: UInt64,
        slippage: Double
    ) throws -> UInt64? {
        guard slippage != 1 else {return nil}
        let estimatedAmount = UInt64(Float64(minimumReceiveAmount) / Float64(1 - slippage))
        return try getInputAmount(fromEstimatedAmount: estimatedAmount)
    }
    
    public func createSwapInstruction(
        userTransferAuthorityPubkey: PublicKey,
        sourceTokenAddress: PublicKey,
        destinationTokenAddress: PublicKey,
        amountIn: UInt64,
        minAmountOut: UInt64
    ) throws -> TransactionInstruction {
        TokenSwapProgram.swapInstruction(
            tokenSwap: try account.toPublicKey(),
            authority: try authority.toPublicKey(),
            userTransferAuthority: userTransferAuthorityPubkey,
            userSource: sourceTokenAddress,
            poolSource: try tokenAccountA.toPublicKey(),
            poolDestination: try tokenAccountB.toPublicKey(),
            userDestination: destinationTokenAddress,
            poolMint: try poolTokenMint.toPublicKey(),
            feeAccount: try feeAccount.toPublicKey(),
            hostFeeAccount: try? hostFeeAccount?.toPublicKey(),
            swapProgramId: swapProgramId,
            tokenProgramId: TokenProgram.id,
            amountIn: amountIn,
            minimumAmountOut: minAmountOut
        )
    }
    
    // MARK: - Internal methods
    func getOutputAmount(
        fromInputAmount inputAmount: UInt64
    ) throws -> UInt64 {
        let fees = try getFee(inputAmount)
        let inputAmountLessFee = inputAmount.minus(fees)
        return try _getOutputAmount(from: inputAmountLessFee)
    }
    
    func getInputAmount(
        fromEstimatedAmount estimatedAmount: UInt64
    ) throws -> UInt64? {
        guard let poolInputAmount = tokenABalance?.amountInUInt64,
              let poolOutputAmount = tokenBBalance?.amountInUInt64
        else {throw OrcaSwapError.accountBalanceNotFound}
        
        if estimatedAmount > poolOutputAmount {
            throw OrcaSwapError.estimatedAmountIsTooHigh
        }
        
        switch curveType {
        case STABLE:
            guard let amp = amp else {throw OrcaSwapError.ampDoesNotExistInPoolConfig}
            let inputAmountLessFee = computeInputAmount(outputAmount: estimatedAmount, inputPoolAmount: poolInputAmount, outputPoolAmount: poolOutputAmount, amp: amp)
            let inputAmount = (BInt(inputAmountLessFee) * BInt(feeDenominator)).divide(BInt(feeDenominator.minus(feeNumerator)))
            return UInt64(inputAmount)
        case CONSTANT_PRODUCT:
            let invariant = BInt(poolInputAmount) * BInt(poolOutputAmount)
            
            let newPoolInputAmount = ceilingDivision(invariant, BInt(poolOutputAmount.minus(estimatedAmount))).quotient
            let inputAmountLessFee = BInt(newPoolInputAmount.minus(poolInputAmount))
            
            let feeRatioNumerator: BInt
            let feeRatioDenominator: BInt
            
            if ownerTradeFeeDenominator == 0 {
                feeRatioNumerator = BInt(feeDenominator)
                feeRatioDenominator = BInt(feeDenominator.minus(feeNumerator))
            } else {
                feeRatioNumerator = BInt(feeDenominator) * BInt(ownerTradeFeeDenominator)
                feeRatioDenominator = BInt(feeDenominator)
                    * BInt(ownerTradeFeeDenominator)
                    - (BInt(feeNumerator) * BInt(ownerTradeFeeDenominator))
                    - (BInt(ownerTradeFeeNumerator) * BInt(feeDenominator))
            }
            
            let inputAmount = (inputAmountLessFee * feeRatioNumerator).divide(feeRatioDenominator)
            return UInt64(inputAmount)
            
        default:
            return nil
        }
    }
    
    func calculatingFees(_ inputAmount: UInt64) throws -> UInt64 {
        let inputFees = try getFee(inputAmount)
        return try _getOutputAmount(from: inputFees)
    }
    
    /// baseOutputAmount is the amount the user would receive if fees are included and slippage is excluded.
    func getBaseOutputAmount(
        inputAmount: UInt64
    ) throws -> UInt64? {
        guard let poolInputAmount = tokenABalance?.amountInUInt64,
              let poolOutputAmount = tokenBBalance?.amountInUInt64
        else {throw OrcaSwapError.accountBalanceNotFound}
        
        let fees = try getFee(inputAmount)
        let inputAmountLessFee = inputAmount.minus(fees)
        
        switch curveType {
        case STABLE:
            guard let amp = amp else {throw OrcaSwapError.ampDoesNotExistInPoolConfig}
            return computeBaseOutputAmount(
                inputAmount: inputAmountLessFee,
                inputPoolAmount: poolInputAmount,
                outputPoolAmount: poolOutputAmount,
                amp: amp
            )
        case CONSTANT_PRODUCT:
            return UInt64((BInt(inputAmountLessFee) * BInt(poolOutputAmount)).divide(BInt(poolInputAmount)))
        default:
            return nil
        }
    }
    
    /// Construct exchange
    func constructExchange(
        tokens: [String: TokenValue],
        blockchainClient: SolanaBlockchainClient,
        owner: PublicKey,
        fromTokenPubkey: String,
        toTokenPubkey: String?,
        amount: Lamports,
        slippage: Double,
        feePayer: PublicKey?,
        minRenExemption: Lamports
    ) async throws -> (AccountInstructions, Lamports /*account creation fee*/) {
        guard let fromMint = try? tokens[tokenAName]?.mint.toPublicKey(),
              let toMint = try? tokens[tokenBName]?.mint.toPublicKey(),
              let fromTokenPubkey = try? fromTokenPubkey.toPublicKey()
        else { throw OrcaSwapError.notFound }
        
        // Create fromTokenAccount when needed
        let sourceAccountInstructions: AccountInstructions
        
        if fromMint == .wrappedSOLMint &&
            owner == fromTokenPubkey
        {
            sourceAccountInstructions = try await blockchainClient.prepareCreatingWSOLAccountAndCloseWhenDone(
                from: owner,
                amount: amount,
                payer: feePayer ?? owner,
                minRentExemption: minRenExemption
            )
        } else {
            sourceAccountInstructions = .init(account: fromTokenPubkey)
        }
        
        // If necessary, create a TokenAccount for the output token
        let destinationAccountInstructions: AccountInstructions
        
        // If destination token is Solana, create WSOL if needed
        if toMint == .wrappedSOLMint {
            if let toTokenPubkey = try? toTokenPubkey?.toPublicKey(),
               toTokenPubkey != owner
            {
                // wrapped sol has already been created, just return it, then close later
                destinationAccountInstructions = .init(
                    account: toTokenPubkey,
                    cleanupInstructions: [
                        TokenProgram.closeAccountInstruction(
                            account: toTokenPubkey,
                            destination: owner,
                            owner: owner
                        )
                    ]
                )
            } else {
                // create wrapped sol
                destinationAccountInstructions = try await blockchainClient.prepareCreatingWSOLAccountAndCloseWhenDone(
                    from: owner,
                    amount: 0,
                    payer: feePayer ?? owner,
                    minRentExemption: minRenExemption
                )
            }
        }
        
        // If destination is another token and has already been created
        else if let toTokenPubkey = try? toTokenPubkey?.toPublicKey() {
            destinationAccountInstructions = .init(account: toTokenPubkey)
        }
        
        // Create associated token address
        else {
            destinationAccountInstructions = try await blockchainClient.prepareForCreatingAssociatedTokenAccount(
                owner: owner,
                mint: toMint,
                feePayer: feePayer ?? owner,
                closeAfterward: false
            )
        }
        
        // form instructions
        var instructions = [TransactionInstruction]()
        var cleanupInstructions = [TransactionInstruction]()
        var accountCreationFee: UInt64 = 0

        // source
        instructions.append(contentsOf: sourceAccountInstructions.instructions)
        cleanupInstructions.append(contentsOf: sourceAccountInstructions.cleanupInstructions)
        if !sourceAccountInstructions.instructions.isEmpty {
            accountCreationFee += minRenExemption
        }

        // destination
        instructions.append(contentsOf: destinationAccountInstructions.instructions)
        cleanupInstructions.append(contentsOf: destinationAccountInstructions.cleanupInstructions)
        if !destinationAccountInstructions.instructions.isEmpty {
            accountCreationFee += minRenExemption
        }

        // swap instructions
        guard let minAmountOut = try? getMinimumAmountOut(inputAmount: amount, slippage: slippage)
        else {throw OrcaSwapError.couldNotEstimatedMinimumOutAmount}

        let swapInstruction = try createSwapInstruction(
            userTransferAuthorityPubkey: owner,
            sourceTokenAddress: sourceAccountInstructions.account,
            destinationTokenAddress: destinationAccountInstructions.account,
            amountIn: amount,
            minAmountOut: minAmountOut
        )

        instructions.append(swapInstruction)

        var signers = [KeyPair]()
        signers.append(contentsOf: sourceAccountInstructions.signers)
        signers.append(contentsOf: destinationAccountInstructions.signers)

        return (.init(
            account: destinationAccountInstructions.account,
            instructions: instructions,
            cleanupInstructions: cleanupInstructions,
            signers: signers
        ), accountCreationFee)
    }
    
    // MARK: - Helpers
    func getFee(_ inputAmount: UInt64) throws -> UInt64 {
        guard curveType == STABLE || curveType == CONSTANT_PRODUCT else {throw OrcaSwapError.unknown}
        let tradingFee = computeFee(baseAmount: inputAmount, feeNumerator: feeNumerator, feeDenominator: feeDenominator)
        let ownerFee = computeFee(baseAmount: inputAmount, feeNumerator: ownerTradeFeeNumerator, feeDenominator: ownerTradeFeeDenominator)
        return tradingFee + ownerFee
        
    }
    
    private func _getOutputAmount(from inputAmount: UInt64) throws -> UInt64 {
        guard let poolInputAmount = tokenABalance?.amountInUInt64,
              let poolOutputAmount = tokenBBalance?.amountInUInt64
        else {throw OrcaSwapError.accountBalanceNotFound}
        
        switch curveType {
        case STABLE:
            guard let amp = amp else {throw OrcaSwapError.ampDoesNotExistInPoolConfig}
            return computeOutputAmount(
                inputAmount: inputAmount,
                inputPoolAmount: poolInputAmount,
                outputPoolAmount: poolOutputAmount,
                amp: amp
            )
        case CONSTANT_PRODUCT:
            let invariant = BInt(poolInputAmount) * BInt(poolOutputAmount)
            let newPoolOutputAmount = ceilingDivision(invariant, BInt(poolInputAmount + inputAmount)).quotient
            return poolOutputAmount.minus(newPoolOutputAmount)
        default:
            throw OrcaSwapError.unknown
        }
    }
    
    private func computeFee(baseAmount: UInt64, feeNumerator: UInt64, feeDenominator: UInt64) -> UInt64 {
        if feeNumerator == 0 {
            return 0
        }
        return UInt64((BInt(baseAmount) * BInt(feeNumerator)).divide(BInt(feeDenominator)))
    }
}

private func ceilingDivision(_ dividend: BInt, _ divisor: BInt) -> (quotient: UInt64, divisor: UInt64) {
    var divisor = divisor
    var quotient = dividend.divide(divisor)
    if quotient == 0 {
        return (quotient: 0, divisor: UInt64(divisor))
    }
    
    var remainder = dividend % divisor
    if remainder > 0 {
        quotient += 1
        divisor = dividend.divide(quotient)
        remainder = dividend.divide(quotient)
        if remainder > 0 {
            divisor += 1
        }
    }
    
    return (quotient: UInt64(quotient), divisor: UInt64(divisor))
}

private func computeOutputAmount(
    inputAmount: UInt64,
    inputPoolAmount: UInt64,
    outputPoolAmount: UInt64,
    amp: UInt64
) -> UInt64 {
    let leverage = amp * N_COINS
    let newInputPoolAmount = inputAmount + inputPoolAmount
    let d = computeD(leverage: leverage, amountA: inputPoolAmount, amountB: outputPoolAmount)
    
    let newOutputPoolAmount = _computeOutputAmount(leverage: leverage, newInputAmount: newInputPoolAmount, d: d)
    let outputAmount = outputPoolAmount.minus(newOutputPoolAmount)
    return outputAmount
}

// A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
private func computeD(leverage: UInt64, amountA: UInt64, amountB: UInt64) -> UInt64 {
    let amountATimesN = BInt(amountA) * BInt(N_COINS) + 1
    let amountBTimesN = BInt(amountB) * BInt(N_COINS) + 1
    let sumX = BInt(amountA) + BInt(amountB)
    
    if sumX == 0 {
        return 0
    }
    
    var dPrevious: BInt
    var d = sumX
    
    for _ in 0..<32 {
        var dProduct = d
        dProduct = (dProduct * d).divide(amountATimesN)
        dProduct = (dProduct * d).divide(amountBTimesN)
        dPrevious = d
        d = BInt(calculateStep(initialD: UInt64(d), leverage: leverage, sumX: UInt64(sumX), dProduct: UInt64(dProduct)))
        if d == dPrevious {
            break
        }
    }
    
    return UInt64(d)
}

// d = (leverage * sum_x + d_product * n_coins) * initial_d / ((leverage - 1) * initial_d + (n_coins + 1) * d_product)
private func calculateStep(
  initialD: UInt64,
  leverage: UInt64,
  sumX: UInt64,
  dProduct: UInt64
) -> UInt64 {
    let leverageMul = BInt(leverage) * BInt(sumX)
    let dPMul = BInt(dProduct) * BInt(N_COINS)
    
    let leverageVal = (leverageMul + dPMul) * BInt(initialD)

    let leverageSub = BInt(initialD) * BInt(leverage.minus(1))
    let nCoinsSum = BInt(dProduct) * BInt(N_COINS + 1)
    
    let rVal = leverageSub + nCoinsSum
    
    return UInt64(leverageVal.divide(rVal))
}

/// Compute swap amount `y` in proportion to `x`
/// Solve for y:
/// y**2 + y * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
/// y**2 + b*y = c
private func _computeOutputAmount(leverage: UInt64, newInputAmount: UInt64, d: UInt64) -> UInt64 {
    let c = (BInt(d) ** Int(N_COINS + 1)).divide((BInt(newInputAmount)) * BInt(N_COINS_SQUARED) * BInt(leverage))
    
    let b = BInt(newInputAmount) + (BInt(d).divide(BInt(leverage)))
    
    var yPrevious: BInt
    var y = BInt(d)
    
    for _ in 0..<32 {
        yPrevious = y
        y = ((y ** 2) + c).divide((y * 2) + b - BInt(d))
        if y == yPrevious {
            break
        }
    }
    
    return UInt64(y)
}

private func computeInputAmount(
  outputAmount: UInt64,
  inputPoolAmount: UInt64,
  outputPoolAmount: UInt64,
  amp: UInt64
) -> UInt64 {
    let leverage = BInt(amp) * BInt(N_COINS)
    let newOutputPoolAmount = BInt(outputPoolAmount) - BInt(outputAmount)
    let d = computeD(
        leverage: UInt64(leverage),
        amountA: outputPoolAmount,
        amountB: inputPoolAmount
    )
    let newInputPoolAmount = _computeOutputAmount(
        leverage: UInt64(leverage),
        newInputAmount: UInt64(newOutputPoolAmount),
        d: d
    )
    
    return newInputPoolAmount.minus(inputPoolAmount)
}


// Take the derivative of the invariant function over x
private func computeBaseOutputAmount(
  inputAmount: UInt64,
  inputPoolAmount: UInt64,
  outputPoolAmount: UInt64,
  amp: UInt64
) -> UInt64 {
    let leverage = BInt(amp) * BInt(N_COINS)
    let invariant = computeD(leverage: UInt64(leverage), amountA: inputPoolAmount, amountB: outputPoolAmount)
    let a = BInt(amp) * 16
    let b = a
    let c = BInt(invariant) * 4 - (BInt(invariant) * BInt(amp) * 16)
    
    let numerator = (a * 2 * BInt(inputPoolAmount) + (b * BInt(outputPoolAmount)) + c)
        * BInt(outputPoolAmount)
    
    let denominator = (a * BInt(inputPoolAmount) + (b * 2 * BInt(outputPoolAmount) + c))
        * BInt(inputPoolAmount)
    
    return UInt64((BInt(inputAmount) * numerator).divide(denominator))
}

private extension UInt64 {
    func minus(_ num: UInt64) -> UInt64 {
        if self <= num {return 0}
        return self - num
    }
}

private extension BInt {
    func divide(_ divider: BInt) -> BInt {
        if divider == 0 {return 0}
        return self / divider
    }
}
