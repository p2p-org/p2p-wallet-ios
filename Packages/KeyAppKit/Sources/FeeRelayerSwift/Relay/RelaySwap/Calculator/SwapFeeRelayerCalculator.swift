// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import OrcaSwapSwift

public protocol SwapFeeRelayerCalculator {
    func calculateSwappingNetworkFees(
        lamportsPerSignature: UInt64,
        minimumTokenAccountBalance: UInt64,
        swapPoolsCount: Int,
        sourceTokenMint: PublicKey,
        destinationTokenMint: PublicKey,
        destinationAddress: PublicKey?
    ) async throws -> FeeAmount
}
