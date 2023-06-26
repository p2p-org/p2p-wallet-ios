// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import OrcaSwapSwift
import SolanaSwift

public class DefaultSwapFeeRelayerCalculator: SwapFeeRelayerCalculator {
    let destinationAnalysator: DestinationAnalysator
    let accountStorage: SolanaAccountStorage
    
    var userAccount: KeyPair { accountStorage.account! }

    public init(destinationAnalysator: DestinationAnalysator, accountStorage: SolanaAccountStorage) {
        self.destinationAnalysator = destinationAnalysator
        self.accountStorage = accountStorage
    }
    
    public func calculateSwappingNetworkFees(
        lamportsPerSignature: UInt64,
        minimumTokenAccountBalance: UInt64,
        swapPoolsCount: Int,
        sourceTokenMint: PublicKey,
        destinationTokenMint: PublicKey,
        destinationAddress: PublicKey?
    ) async throws -> FeeAmount {
        var expectedFee = FeeAmount.zero

        // fee for payer's signature
        expectedFee.transaction += lamportsPerSignature

        // fee for owner's signature
        expectedFee.transaction += lamportsPerSignature

        // CHECK SOURCE
        // when source token is native SOL
        if sourceTokenMint == PublicKey.wrappedSOLMint {
            expectedFee.transaction += lamportsPerSignature
        }

        // CHECK DESTINATION
        // when destination is native SOL
        if destinationTokenMint == PublicKey.wrappedSOLMint {
            expectedFee.transaction += lamportsPerSignature
        }
        
        // when destination is not native SOL and needs to be created
        else if destinationAddress == nil {
            // analyse the destination
            let result = try await destinationAnalysator.analyseDestination(
                owner: userAccount.publicKey,
                mint: destinationTokenMint
            )
            
            // if destination is non-created spl token, then add the fee
            switch result {
            case .splAccount(let needsCreation) where needsCreation:
                expectedFee.accountBalances += minimumTokenAccountBalance
            default:
                break
            }
        }

        // CHECK OTHER
        // in transitive swap, there will be situation when swapping from SOL -> SPL that needs spliting transaction to 2 transactions
        if swapPoolsCount == 2, sourceTokenMint == PublicKey.wrappedSOLMint, destinationAddress == nil {
            expectedFee.transaction += lamportsPerSignature * 2
        }

        return expectedFee
    }
}
