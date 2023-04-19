//
//  File.swift
//
//
//  Created by Giang Long Tran on 31.03.2023.
//

import BigInt
import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift

enum WormholeSendInputLogic {
    /// Find an account, that will convert the fees. Max input amount also be returned.
    static func autoSelectFeePayer(
        fee: CryptoAmount,
        accountCreationFee: CryptoAmount,
        selectedAccount: SolanaAccount,
        availableAccounts: [SolanaAccount],
        transferAmount: CryptoAmount,
        feeCalculator: RelayFeeCalculator,
        orcaSwap: OrcaSwapType,
        minSOLBalance: CryptoAmount,
        relayContext: RelayContext
    ) async throws -> (account: SolanaAccount, feeAmount: CryptoAmount) {
        guard
            fee.token.symbol == "SOL",
            minSOLBalance.token.symbol == "SOL"
        else {
            throw WormholeSendInputError.invalidBaseFeeToken
        }

        // Build all possible candidates for paying fee
        var feePayerCandidates: [SolanaAccount] = [
            // Same account
            availableAccounts.first(where: { account in
                account.data.token.address == selectedAccount.data.token.address
            }),

            // Native account
            availableAccounts.nativeWallet,
        ].compactMap { $0 }

        // Account with high amount in fiat
        let nextAvailableAccounts = availableAccounts
            .filter { account in
                // Exclude first two cases
                account.data.token.address != selectedAccount.data.token.address || !account.data.isNativeSOL
            }
            .sorted(by: { lhs, rhs in
                guard
                    let lhsAmount = lhs.amountInFiat,
                    let rhsAmount = rhs.amountInFiat
                else {
                    return false
                }

                return lhsAmount > rhsAmount
            })
            .prefix(10)

        feePayerCandidates.append(contentsOf: nextAvailableAccounts)

        var feePayerBestCandidate: SolanaAccount?
        var feeAmountForBestCandidate: CryptoAmount?

        // Try find best candidate.
        for feePayerCandidate in feePayerCandidates {
            if feePayerCandidate.data.isNativeSOL {
                // Fee payer candidate is SOL

                let neededTopUpAmount = try await feeCalculator.calculateNeededTopUpAmount(
                    relayContext,
                    expectedFee: .init(
                        transaction: try UInt64(fee.value),
                        accountBalances: try UInt64(accountCreationFee.value)
                    ),
                    payingTokenMint: try PublicKey(string: feePayerCandidate.data.token.address)
                )

                let fee = CryptoAmount(uint64: neededTopUpAmount.total, token: SolanaToken.nativeSolana)

                if selectedAccount.data.isNativeSOL {
                    // Fee payer candidate and selected account is same.

                    if (transferAmount + fee) == feePayerCandidate.cryptoAmount {
                        // Solana account will be zero
                        feePayerBestCandidate = feePayerCandidate
                        feeAmountForBestCandidate = fee

                        break
                    } else if (transferAmount + fee + minSOLBalance) <= feePayerCandidate.cryptoAmount {
                        // Solana account will be greater or equal than min sol balance.
                        feePayerBestCandidate = feePayerCandidate
                        feeAmountForBestCandidate = fee

                        break
                    }
                } else {
                    // Selected account is a SPL token.

                    if fee <= feePayerCandidate.cryptoAmount {
                        feePayerBestCandidate = feePayerCandidate
                        feeAmountForBestCandidate = fee
                    }
                }

            } else {
                // Fee payer candidate is SPL token
                
                let neededTopUpAmount = try await feeCalculator.calculateNeededTopUpAmount(
                    relayContext,
                    expectedFee: .init(
                        transaction: try UInt64(fee.value),
                        accountBalances: try UInt64(accountCreationFee.value)
                    ),
                    payingTokenMint: try PublicKey(string: feePayerCandidate.data.token.address)
                )

                let fee = CryptoAmount(uint64: neededTopUpAmount.total, token: SolanaToken.nativeSolana)

                do {
                    let feeInToken = try await feeCalculator.calculateFeeInPayingToken(
                        orcaSwap: orcaSwap,
                        feeInSOL: .init(transaction: UInt64(fee.value), accountBalances: 0),
                        payingFeeTokenMint: PublicKey(string: feePayerCandidate.data.token.address)
                    )

                    if (feeInToken?.total ?? 0) < (feePayerCandidate.data.lamports ?? 0) {
                        feePayerBestCandidate = feePayerCandidate
                        feeAmountForBestCandidate = CryptoAmount(
                            uint64: feeInToken?.total ?? 0,
                            token: feePayerCandidate.data.token
                        )

                        break
                    }
                } catch {
                    print(error)
                    continue
                }
            }
        }

        if
            let feePayerBestCandidate,
            let feeAmountForBestCandidate
        {
            return (feePayerBestCandidate, feeAmountForBestCandidate)
        } else {
            throw WormholeSendInputError.calculationFeePayerFailure
        }
    }
}
