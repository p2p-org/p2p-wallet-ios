//
//  PT.Models.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import RxSwift
import SolanaSwift

// MARK: - Transaction type

protocol RawTransactionType {
    func createRequest() -> Single<String>
    var mainDescription: String { get }
    var networkFees: (total: SolanaSDK.Lamports, token: SolanaSDK.Token)? { get }
}

extension RawTransactionType {
    var isSwap: Bool { self is ProcessTransaction.SwapTransaction }

    var payingWallet: Wallet? {
        switch self {
        case let transaction as ProcessTransaction.SwapTransaction:
            return transaction.payingWallet
        case let transaction as ProcessTransaction.SendTransaction:
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
        let poolsPair: Swap.PoolsPair
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

        func createRequest() -> Single<String> {
            // check if payingWallet has enough balance to cover fee
            if let fees = fees.networkFees,
               let payingWallet = payingWallet,
               let currentAmount = payingWallet.lamports,
               fees.total > currentAmount
            {
                return .error(SolanaSDK.Error.other(
                    L10n.yourAccountDoesNotHaveEnoughToCoverFees(payingWallet.token.symbol)
                        + ". "
                        + L10n
                        .needsAtLeast(
                            "\(fees.total.convertToBalance(decimals: payingWallet.token.decimals)) \(payingWallet.token.symbol)"
                        )
                        + ". "
                        + L10n.pleaseChooseAnotherTokenAndTryAgain
                ))
            }

            return swapService.swap(
                sourceAddress: sourceWallet.pubkey!,
                sourceTokenMint: sourceWallet.mintAddress,
                destinationAddress: destinationWallet.pubkey,
                destinationTokenMint: destinationWallet.mintAddress,
                payingTokenAddress: payingWallet?.pubkey,
                payingTokenMint: payingWallet?.mintAddress,
                poolsPair: poolsPair,
                amount: amount.toLamport(decimals: sourceWallet.token.decimals),
                slippage: slippage
            ).map { $0.first ?? "" }
        }

        var networkFees: (total: SolanaSDK.Lamports, token: SolanaSDK.Token)? {
            guard let networkFees = fees.networkFees?.total,
                  let payingFeeToken = payingWallet?.token
            else {
                return nil
            }
            return (total: networkFees, payingFeeToken)
        }
    }

    struct CloseTransaction: RawTransactionType {
        let solanaSDK: SolanaSDK
        let closingWallet: Wallet
        let reimbursedAmount: UInt64

        var mainDescription: String {
            L10n.closeAccount(closingWallet.token.symbol)
        }

        func createRequest() -> Single<String> {
            guard let pubkey = closingWallet.pubkey else {
                return .error(SolanaSDK.Error.unknown)
            }
            return solanaSDK.closeTokenAccount(tokenPubkey: pubkey)
        }

        var networkFees: (total: SolanaSDK.Lamports, token: SolanaSDK.Token)? {
            (total: 5000, token: .nativeSolana) // TODO: Fix later
        }
    }

    struct SendTransaction: RawTransactionType {
        let sendService: SendServiceType
        let network: SendToken.Network
        let sender: Wallet
        let receiver: SendToken.Recipient
        let authority: String?
        let amount: SolanaSDK.Lamports
        let payingFeeWallet: Wallet?
        let feeInSOL: UInt64
        let feeInToken: SolanaSDK.FeeAmount?
        let isSimulation: Bool

        var mainDescription: String {
            amount.convertToBalance(decimals: sender.token.decimals)
                .toString(maximumFractionDigits: 9) +
                " " +
                sender.token
                .symbol + " → " + (receiver.name ?? receiver.address.truncatingMiddle(numOfSymbolsRevealed: 4))
        }

        func createRequest() -> Single<String> {
            sendService.send(
                from: sender,
                receiver: receiver.address,
                amount: amount.convertToBalance(decimals: sender.token.decimals),
                network: network,
                payingFeeWallet: payingFeeWallet
            )
        }

        var networkFees: (total: SolanaSDK.Lamports, token: SolanaSDK.Token)? {
            guard let feeInToken = feeInToken, let token = payingFeeWallet?.token else {
                return nil
            }
            return (total: feeInToken.total, token: token)
        }
    }
}

// MARK: - Transaction status

extension ProcessTransaction {
    enum Error: Swift.Error {
        case notEnoughNumberOfConfirmations
    }
}
