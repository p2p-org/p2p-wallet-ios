// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    static func changeFeeToken(
        state: SendInputState,
        feeToken: Token,
        services: SendInputServices
    ) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(
                status: .error(reason: .missingFeeRelayer),
                tokenFee: feeToken
            )
        }

        do {
            let fee = try await services.feeService.getFees(
                from: state.token,
                recipient: state.recipient,
                recipientAdditionalInfo: state.recipientAdditionalInfo,
                payingTokenMint: feeToken.address,
                feeRelayerContext: feeRelayerContext
            ) ?? .zero

            let feeInToken = try? await services.swapService.calculateFeeInPayingToken(
                feeInSOL: fee,
                payingFeeTokenMint: try PublicKey(string: feeToken.address)
            ) ?? .zero

            let state = state.copy(
                fee: fee,
                tokenFee: feeToken,
                feeInToken: feeInToken
            )

            return await validateFee(state: state)
        } catch {
            return await handleFeeCalculationError(state: state, services: services, error: error)
        }
    }
}
