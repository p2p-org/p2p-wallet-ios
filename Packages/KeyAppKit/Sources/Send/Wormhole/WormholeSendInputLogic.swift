//
//  File.swift
//
//
//  Created by Giang Long Tran on 31.03.2023.
//

import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift

enum WormholeSendInputLogic {
    static func autoSelectFeePayer(
        fee: CryptoAmount,
        selectedAccount: SolanaAccount,
        availableAccounts: [SolanaAccount],
        transferAmount: CryptoAmount,
        feeCalculator: RelayFeeCalculator,
        orcaSwap: OrcaSwapType
    ) async throws -> SolanaAccount {
        // Build all possible candidates for paying fee
        let feePayerCandidates: [SolanaAccount] = [
            // Same account
            availableAccounts.first(where: { account in
                account.data.token.address == selectedAccount.data.token.address
            }),

            // Account with high amount in fiat
            availableAccounts.sorted(by: { lhs, rhs in
                guard
                    let lhsAmount = lhs.amountInFiat,
                    let rhsAmount = rhs.amountInFiat
                else {
                    return false
                }

                return lhsAmount > rhsAmount
            })
            .first,

            // Native account
            availableAccounts.nativeWallet,
        ].compactMap { $0 }

        var feePayerBestCandidate: SolanaAccount?

        // Try find best candidate.
        for feePayerCandidate in feePayerCandidates {
            if feePayerCandidate.data.isNativeSOL {
                if (transferAmount + fee) < feePayerCandidate.cryptoAmount {
                    feePayerBestCandidate = feePayerCandidate
                    break
                }
            } else {
                do {
                    let feeInToken = try await feeCalculator.calculateFeeInPayingToken(
                        orcaSwap: orcaSwap,
                        feeInSOL: .init(transaction: UInt64(fee.value), accountBalances: 0),
                        payingFeeTokenMint: PublicKey(string: feePayerCandidate.data.token.address)
                    )

                    if (feeInToken?.total ?? 0) < (feePayerCandidate.data.lamports ?? 0) {
                        feePayerBestCandidate = feePayerCandidate
                        break
                    }
                } catch {
                    continue
                }
            }
        }

        guard let feePayerBestCandidate = feePayerBestCandidate ?? availableAccounts.nativeWallet else {
            throw WormholeSendInputError.calculationFeePayerFailure
        }

        return feePayerBestCandidate
    }
}
