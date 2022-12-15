//
//  PT.Models.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import SolanaSwift
import OrcaSwapSwift

// MARK: - Transaction type

protocol RawTransactionType {
    func createRequest() async throws -> String
    var mainDescription: String { get }
    var networkFees: (total: SolanaSwift.Lamports, token: SolanaSwift.Token)? { get }
}

extension RawTransactionType {
    var isSwap: Bool { self is ProcessTransaction.SwapTransaction }

    var payingWallet: Wallet? {
        switch self {
        case let transaction as ProcessTransaction.SwapTransaction:
            return transaction.payingWallet
        case let transaction as SendTransaction:
            return transaction.payingFeeWallet
        default:
            return nil
        }
    }
}

extension ProcessTransaction {
    struct SwapTransaction: RawTransactionType {
        struct MetaInfo {
            let swapMAX: Bool
            let swapUSD: Double
        }

        let swapService: SwapServiceType
        let sourceWallet: Wallet
        let destinationWallet: Wallet
        let payingWallet: Wallet?
        let authority: String?
        let poolsPair: PoolsPair
        let amount: Double
        let estimatedAmount: Double
        let slippage: Double
        let fees: [PayingFee]
        let metaInfo: MetaInfo

        var mainDescription: String {
            amount.toString(maximumFractionDigits: 9) + " " + sourceWallet.token.symbol +
                " → " +
                estimatedAmount.toString(maximumFractionDigits: 9) + " " + destinationWallet.token.symbol
        }

        func createRequest() async throws -> String {
            // check if payingWallet has enough balance to cover fee
            if let fees = fees.networkFees,
               let payingWallet = payingWallet,
               let currentAmount = payingWallet.lamports,
               fees.total > currentAmount
            {
                throw SolanaError.other(
                    L10n.yourAccountDoesNotHaveEnoughToCoverFees(payingWallet.token.symbol)
                        + ". "
                        + L10n
                        .needsAtLeast(
                            "\(fees.total.convertToBalance(decimals: payingWallet.token.decimals)) \(payingWallet.token.symbol)"
                        )
                        + ". "
                        + L10n.pleaseChooseAnotherTokenAndTryAgain
                )
            }

            return try await swapService.swap(
                sourceAddress: sourceWallet.pubkey!,
                sourceTokenMint: sourceWallet.mintAddress,
                destinationAddress: destinationWallet.pubkey,
                destinationTokenMint: destinationWallet.mintAddress,
                payingTokenAddress: payingWallet?.pubkey,
                payingTokenMint: payingWallet?.mintAddress,
                poolsPair: poolsPair,
                amount: amount.toLamport(decimals: sourceWallet.token.decimals),
                slippage: slippage
            ).last ?? ""
        }

        var networkFees: (total: Lamports, token: Token)? {
            guard let networkFees = fees.networkFees?.total,
                  let payingFeeToken = payingWallet?.token
            else {
                return nil
            }
            return (total: networkFees, payingFeeToken)
        }
    }

    struct CloseTransaction: RawTransactionType {
        let closingWallet: Wallet
        let reimbursedAmount: UInt64

        var mainDescription: String {
            L10n.closeAccount(closingWallet.token.symbol)
        }

        func createRequest() async throws -> String {
            fatalError("Not implemented")
            // guard let pubkey = closingWallet.pubkey else {
            //     return .error(Error.unknown)
            // }
            // return closeTokenAccount(tokenPubkey: pubkey)
        }

        var networkFees: (total: Lamports, token: Token)? {
            (total: 5000, token: .nativeSolana) // TODO: Fix later
        }
    }
}

// MARK: - Transaction status

extension ProcessTransaction {
    enum Error: Swift.Error {
        case notEnoughNumberOfConfirmations
    }
}
