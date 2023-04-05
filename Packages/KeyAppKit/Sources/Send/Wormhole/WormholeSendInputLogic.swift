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
        selectedAccount: SolanaAccount,
        availableAccounts: [SolanaAccount],
        transferAmount: CryptoAmount,
        feeCalculator: RelayFeeCalculator,
        orcaSwap: OrcaSwapType,
        minSOLBalance: CryptoAmount
    ) async throws -> (account: SolanaAccount, feeAmount: CryptoAmount) {
        guard
            fee.token.symbol == "SOL",
            minSOLBalance.token.symbol == "SOL"
        else {
            throw WormholeSendInputError.invalidBaseFeeToken
        }

        // Build all possible candidates for paying fee
        let feePayerCandidates: [SolanaAccount] = [
            // Same account
            availableAccounts.first(where: { account in
                account.data.token.address == selectedAccount.data.token.address
            }),

            // Native account
            availableAccounts.nativeWallet,

            // Account with high amount in fiat
            availableAccounts
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
                .first,
        ].compactMap { $0 }

        var feePayerBestCandidate: SolanaAccount?
        var feeAmountForBestCandidate: CryptoAmount?

        // Try find best candidate.
        for feePayerCandidate in feePayerCandidates {
            if feePayerCandidate.data.isNativeSOL {
                // Fee payer candidate is SOL
                
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
