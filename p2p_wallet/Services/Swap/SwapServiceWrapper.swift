//
//  SwapServiceWrapper.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.11.2022.
//

import Foundation
import FeeRelayerSwift
import OrcaSwapSwift
import Send
import SolanaSwift
import Resolver

class SwapServiceWrapper: Send.SwapService {
    @Injected var orcaSwap: OrcaSwap
    @Injected var feeRelayer: FeeRelayer
    
    func calculateFeeInPayingToken(feeInSOL: SolanaSwift.FeeAmount, payingFeeTokenMint: SolanaSwift.PublicKey) async throws -> SolanaSwift.FeeAmount? {
        try await orcaSwap.load()
        return try await feeRelayer.feeCalculator.calculateFeeInPayingToken(orcaSwap: orcaSwap, feeInSOL: feeInSOL, payingFeeTokenMint: payingFeeTokenMint)
    }
}
