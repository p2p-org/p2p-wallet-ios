// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    static func sendInputChangeAmountInFiat(
        state: SendInputState,
        amount: Double,
        services: SendInputServices
    ) async -> SendInputState {
        guard let price = state.userWalletEnvironments.exchangeRate[state.token.symbol]?.value else {
            return await sendInputChangeAmountInToken(state: state, amount: 0, services: services)
        }
        let amountInToken = amount / price
        return await sendInputChangeAmountInToken(state: state, amount: amountInToken, services: services)
    }

    static func sendInputChangeAmountInToken(
        state: SendInputState,
        amount: Double,
        services _: SendInputServices
    ) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(status: .error(reason: .missingFeeRelayer))
        }

        let amountLamports = amount.toLamport(decimals: state.token.decimals)

        var status: SendInputState.Status = .ready

        // Limit amount with logic for SPL and SOL tokens
        if state.token.isNativeSOL {
            let maxAmount = state.maxAmountInputInToken.toLamport(decimals: state.token.decimals)
            let maxAmountWithLeftAmount = state.maxAmountInputInSOLWithLeftAmount.toLamport(decimals: state.token.decimals)
            let minAmount = feeRelayerContext.minimumRelayAccountBalance

            if amountLamports > maxAmountWithLeftAmount {
                if amountLamports == maxAmount {
                    // Return availability to send the absolute max amount for SOL token
                    status = .ready
                } else {
                    let limit = amountLamports < maxAmount ? state.maxAmountInputInSOLWithLeftAmount : state.maxAmountInputInToken
                    status = .error(reason: .inputTooHigh(limit))
                }
            }

            if state.recipientAdditionalInfo.walletAccount == nil {
                // Minimum amount to send to the account with no funds
                if minAmount > maxAmountWithLeftAmount && amountLamports < maxAmount {
                    // If minimum appears to be less than available maximum than return this error
                    status = .error(reason: .insufficientFunds)
                } else if amountLamports < minAmount {
                    status = .error(reason: .inputTooLow(minAmount.convertToBalance(decimals: state.token.decimals)))
                }
            }

        } else if amountLamports > state.maxAmountInputInToken.toLamport(decimals: state.token.decimals) {
            status = .error(reason: .inputTooHigh(state.maxAmountInputInToken))
        }

        if !checkIsReady(state) {
            status = .error(reason: .requiredInitialize)
        }

        var state = state.copy(
            status: status,
            amountInFiat: amount * (state.userWalletEnvironments.exchangeRate[state.token.symbol]?.value ?? 0),
            amountInToken: amount
        )

        state = await validateFee(state: state)

        return state
    }
}
