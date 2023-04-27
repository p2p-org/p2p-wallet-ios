// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    static func changeToken(
        state: SendInputState,
        token: Token,
        services: SendInputServices
    ) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(
                status: .error(reason: .missingFeeRelayer),
                token: token
            )
        }

        do {
            // Update fee in SOL and source token
            let fee: FeeAmount
            if state.isSendingViaLink {
                fee = .zero
            } else {
                fee = try await services.feeService.getFees(
                    from: token,
                    recipient: state.recipient,
                    recipientAdditionalInfo: state.recipientAdditionalInfo,
                    payingTokenMint: state.tokenFee.address,
                    feeRelayerContext: feeRelayerContext
                ) ?? .zero
            }
            
            var state = state.copy(
                token: token,
                fee: fee,
                minAmount: .zero
            )

            // Auto select fee token
            if state.isSendingViaLink {
                // do nothing as fee is free
            } else {
                let feeInfo = await autoSelectTokenFee(
                    userWallets: state.userWalletEnvironments.wallets,
                    feeInSol: state.fee,
                    token: state.token,
                    services: services
                )
                
                state = state.copy(
                    tokenFee: feeInfo.token,
                    feeInToken: fee == .zero ? .zero : feeInfo.fee
                )
            }
            
            state = await sendInputChangeAmountInToken(state: state, amount: state.amountInToken, services: services)
            state = await validateFee(state: state)

            print(state.status)
            return state
        } catch {
            return state.copy(status: .error(reason: .unknown(error as NSError)))
        }
    }

    static func validateFee(state: SendInputState) async -> SendInputState {
        guard state.fee != .zero else { return state }
        guard let wallet: Wallet = state.userWalletEnvironments.wallets
            .first(where: { (wallet: Wallet) in wallet.token.address == state.tokenFee.address })
        else {
            return state.copy(status: .error(reason: .insufficientAmountToCoverFee))
        }

        if state.feeInToken.total > (wallet.lamports ?? 0) {
            return state.copy(status: .error(reason: .insufficientAmountToCoverFee))
        }

        return state
    }

    static func autoSelectTokenFee(
        userWallets: [Wallet],
        feeInSol: FeeAmount,
        token: Token,
        services: SendInputServices
    ) async -> (token: Token, fee: FeeAmount?) {
        var preferOrder = ["SOL": 2]
        if !preferOrder.keys.contains(token.symbol) {
            preferOrder[token.symbol] = 1
        }

        let sortedWallets = userWallets.sorted { (lhs: Wallet, rhs: Wallet) -> Bool in
            let lhsValue = (preferOrder[lhs.token.symbol] ?? 3)
            let rhsValue = (preferOrder[rhs.token.symbol] ?? 3)

            if lhsValue < rhsValue {
                return true
            } else if lhsValue == rhsValue {
                let lhsCost = lhs.amount ?? 0
                let rhsCost = rhs.amount ?? 0

                return lhsCost < rhsCost
            }

            return false
        }

        for wallet in sortedWallets {
            do {
                let feeInToken: FeeAmount = (try await services.swapService.calculateFeeInPayingToken(
                    feeInSOL: feeInSol,
                    payingFeeTokenMint: try PublicKey(string: wallet.token.address)
                )) ?? .zero

                if feeInToken.total <= (wallet.lamports ?? 0) {
                    return (wallet.token, feeInToken)
                }
            } catch {
                continue
            }
        }

        return (.nativeSolana, feeInSol)
    }
}
