// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SolanaSwift
import FeeRelayerSwift
import OrcaSwapSwift

public protocol SwapService {
    func calculateFeeInPayingToken(feeInSOL: FeeAmount, payingFeeTokenMint: PublicKey) async throws -> FeeAmount?
}

public struct MockedSwapService: SwapService {
    let result: FeeAmount?

    public init(result: FeeAmount?) { self.result = result }

    public func calculateFeeInPayingToken(
        feeInSOL _: FeeAmount,
        payingFeeTokenMint _: PublicKey
    ) async throws -> FeeAmount? { result }
}

public class SwapServiceImpl: SwapService {
    private let feeRelayerCalculator: RelayFeeCalculator
    private let orcaSwap: OrcaSwapType

    public init(
        feeRelayerCalculator: RelayFeeCalculator,
        orcaSwap: OrcaSwapType
    ) {
        self.feeRelayerCalculator = feeRelayerCalculator
        self.orcaSwap = orcaSwap
    }

    public func calculateFeeInPayingToken(feeInSOL: FeeAmount, payingFeeTokenMint: PublicKey) async throws -> FeeAmount? {
        try await feeRelayerCalculator.calculateFeeInPayingToken(orcaSwap: orcaSwap, feeInSOL: feeInSOL, payingFeeTokenMint: payingFeeTokenMint)
    }
}
