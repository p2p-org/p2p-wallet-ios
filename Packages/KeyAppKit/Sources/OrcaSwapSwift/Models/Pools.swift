//
//  File.swift
//  
//
//  Created by Chung Tran on 13/10/2021.
//

import Foundation
import SolanaSwift

public typealias Pools = [String: Pool] // [poolId: string]: PoolConfig;
public typealias PoolsPair = [Pool]
private let lock = NSLock()

public extension PoolsPair {
    func constructExchange(
        tokens: [String: TokenValue],
        blockchainClient: SolanaBlockchainClient,
        owner: PublicKey,
        fromTokenPubkey: String,
        intermediaryTokenAddress: String? = nil,
        toTokenPubkey: String?,
        amount: Lamports,
        slippage: Double,
        feePayer: PublicKey?,
        minRenExemption: Lamports
    ) async throws -> (AccountInstructions, Lamports /*account creation fee*/) {
        guard count > 0 && count <= 2 else { throw OrcaSwapError.invalidPool }

        if count == 1 {
            // direct swap
            return try await self[0].constructExchange(
                tokens: tokens,
                blockchainClient: blockchainClient,
                owner: owner,
                fromTokenPubkey: fromTokenPubkey,
                toTokenPubkey: toTokenPubkey,
                amount: amount,
                slippage: slippage,
                feePayer: feePayer,
                minRenExemption: minRenExemption
            )
        } else {
            // transitive swap
            guard let intermediaryTokenAddress = intermediaryTokenAddress else {
                throw OrcaSwapError.intermediaryTokenAddressNotFound
            }
            
            guard let amount = try self[0].getMinimumAmountOut(inputAmount: amount, slippage: slippage)
            else {
                throw OrcaSwapError.unknown
            }
            
            // first construction
            let (pool0AccountInstructions, pool0AccountCreationFee) = try await self[0].constructExchange(
                tokens: tokens,
                blockchainClient: blockchainClient,
                owner: owner,
                fromTokenPubkey: fromTokenPubkey,
                toTokenPubkey: intermediaryTokenAddress,
                amount: amount,
                slippage: slippage,
                feePayer: feePayer,
                minRenExemption: minRenExemption
            )

            let (pool1AccountInstructions, pool1AccountCreationFee) = try await self[1].constructExchange(
                tokens: tokens,
                blockchainClient: blockchainClient,
                owner: owner,
                fromTokenPubkey: intermediaryTokenAddress,
                toTokenPubkey: toTokenPubkey,
                amount: amount,
                slippage: slippage,
                feePayer: feePayer,
                minRenExemption: minRenExemption
            )
            
            return (.init(
                account: pool1AccountInstructions.account,
                instructions: pool0AccountInstructions.instructions + pool1AccountInstructions.instructions,
                cleanupInstructions: pool0AccountInstructions.cleanupInstructions + pool1AccountInstructions.cleanupInstructions,
                signers: pool0AccountInstructions.signers + pool1AccountInstructions.signers
            ), pool0AccountCreationFee + pool1AccountCreationFee)
        }
    }
    
    func getOutputAmount(
        fromInputAmount inputAmount: UInt64
    ) -> UInt64? {
        guard count > 0 else {return nil}
        let pool0 = self[0]
        guard let estimatedAmountOfPool0 = try? pool0.getOutputAmount(fromInputAmount: inputAmount)
        else {return nil}
        
        // direct
        if count == 1 {
            return estimatedAmountOfPool0
        }
        // transitive
        else {
            let pool1 = self[1]
            guard let estimatedAmountOfPool1 = try? pool1.getOutputAmount(fromInputAmount: estimatedAmountOfPool0)
            else {return nil}
            
            return estimatedAmountOfPool1
        }
    }
    
    func getInputAmount(
        fromEstimatedAmount estimatedAmount: UInt64
    ) -> UInt64? {
        guard count > 0 else {return nil}
        
        // direct
        if count == 1 {
            let pool0 = self[0]
            guard let inputAmountOfPool0 = try? pool0.getInputAmount(fromEstimatedAmount: estimatedAmount)
            else {return nil}
            return inputAmountOfPool0
        }
        // transitive
        else {
            let pool1 = self[1]
            guard let inputAmountOfPool1 = try? pool1.getInputAmount(fromEstimatedAmount: estimatedAmount)
            else {return nil}
            let pool0 = self[0]
            
            guard let inputAmountOfPool0 = try? pool0.getInputAmount(fromEstimatedAmount: inputAmountOfPool1)
            else {return nil}
            return inputAmountOfPool0
        }
    }
    
    func getInputAmount(
        minimumAmountOut: UInt64,
        slippage: Double
    ) -> UInt64? {
        guard count > 0 else {return nil}
        let pool0 = self[0]
        // direct
        if count == 1 {
            guard let inputAmount = try? pool0.getInputAmount(minimumReceiveAmount: minimumAmountOut, slippage: slippage)
            else {return nil}
            return inputAmount
        } else {
            let pool1 = self[1]
            guard let inputAmountPool1 = try? pool1.getInputAmount(minimumReceiveAmount: minimumAmountOut, slippage: slippage),
                  let inputAmountPool0 = try? pool0.getInputAmount(minimumReceiveAmount: inputAmountPool1, slippage: slippage)
            else {return nil}
            return inputAmountPool0
        }
    }
    
    func getMinimumAmountOut(
        inputAmount: UInt64,
        slippage: Double
    ) -> UInt64? {
        guard count > 0 else {return nil}
        let pool0 = self[0]
        // direct
        if count == 1 {
            guard let minimumAmountOut = try? pool0.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
            else {return nil}
            return minimumAmountOut
        }
        // transitive
        else {
            guard let outputAmountOfPool0 = try? pool0.getOutputAmount(fromInputAmount: inputAmount)
            else {return nil}
            
            let pool1 = self[1]
            guard let minimumAmountOut = try? pool1.getMinimumAmountOut(inputAmount: outputAmountOfPool0, slippage: slippage)
            else {return nil}
            return minimumAmountOut
        }
    }
    
    func getIntermediaryToken(
        inputAmount: UInt64,
        slippage: Double
    ) -> InterTokenInfo? {
        guard count > 1 else {return nil}
        let pool0 = self[0]
        return .init(
            tokenName: pool0.tokenBName,
            outputAmount: try? pool0.getOutputAmount(fromInputAmount: inputAmount),
            minAmountOut: try? pool0.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage),
            isStableSwap: self[1].isStable == true
        )
    }
    
    func calculateLiquidityProviderFees(
        inputAmount: Double,
        slippage: Double
    ) throws -> [UInt64] {
        guard count > 1 else {return []}
        let pool0 = self[0]
        
        guard let sourceDecimals = pool0.tokenABalance?.decimals else {throw OrcaSwapError.unknown}
        let inputAmount = inputAmount.toLamport(decimals: sourceDecimals)
                
        // 1 pool
        var result = [UInt64]()
        let fee0 = try pool0.calculatingFees(inputAmount)
        result.append(fee0)
        
        // 2 pool
        if count == 2 {
            let pool1 = self[1]
            if let inputAmount = try? pool0.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage) {
                let fee1 = try pool1.calculatingFees(inputAmount)
                result.append(fee1)
            }
        }
        return result
    }
    
    /// baseOutputAmount is the amount the user would receive if fees are included and slippage is excluded.
    private func getBaseOutputAmount(
        inputAmount: UInt64
    ) -> UInt64? {
        guard count > 0 else {return nil}
        let pool0 = self[0]
        guard let outputAmountOfPool0 = try? pool0.getBaseOutputAmount(inputAmount: inputAmount)
        else {return nil}
        
        // direct
        if count == 1 {
            return outputAmountOfPool0
        }
        // transitive
        else {
            let pool1 = self[1]
            guard let outputAmountOfPool1 = try? pool1.getBaseOutputAmount(inputAmount: outputAmountOfPool0)
            else {return nil}
            
            return outputAmountOfPool1
        }
    }
    
    /// price impact
    func getPriceImpact(
        inputAmount: UInt64,
        outputAmount: UInt64
    ) -> BDouble? {
        guard let baseOutputAmount = getBaseOutputAmount(inputAmount: inputAmount)
        else {return nil}
        
        let inputAmountDecimal = BDouble(inputAmount.convertToBalance(decimals: 0))
        let baseOutputAmountDecimal = BDouble(baseOutputAmount.convertToBalance(decimals: 0))
        
        return (baseOutputAmountDecimal - inputAmountDecimal) / baseOutputAmountDecimal * 100
    }
}
