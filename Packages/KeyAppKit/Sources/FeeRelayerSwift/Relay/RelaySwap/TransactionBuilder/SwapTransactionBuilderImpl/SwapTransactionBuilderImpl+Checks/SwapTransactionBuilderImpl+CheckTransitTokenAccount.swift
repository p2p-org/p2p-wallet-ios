//
//  File.swift
//  
//
//  Created by Chung Tran on 06/11/2022.
//

import Foundation
import SolanaSwift
import OrcaSwapSwift

extension SwapTransactionBuilderImpl {
    func checkTransitTokenAccount(
        owner: PublicKey,
        poolsPair: PoolsPair,
        output: inout SwapTransactionBuilderOutput
    ) async throws {
        let transitToken = try? transitTokenAccountManager.getTransitToken(
            pools: poolsPair
        )
        
        let needsCreateTransitTokenAccount = try await transitTokenAccountManager
            .checkIfNeedsCreateTransitTokenAccount(
                transitToken: transitToken
            )

        output.needsCreateTransitTokenAccount = needsCreateTransitTokenAccount
        output.transitTokenAccountAddress = transitToken?.address
        output.transitTokenMintPubkey = transitToken?.mint
    }
}
