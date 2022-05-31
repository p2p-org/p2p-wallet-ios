//
//  SendService+RelayMethod.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2022.
//

import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

extension SendService {
    func getFeeViaRelayMethod(
        _ context: FeeRelayerContext,
        from wallet: Wallet,
        receiver: String,
        payingTokenMint: String?
    ) async throws -> FeeAmount? {
        var transactionFee: UInt64 = 0

        // owner's signature
        transactionFee += context.lamportsPerSignature

        // feePayer's signature
        transactionFee += context.lamportsPerSignature

        let isAssociatedTokenUnregister: Bool
        if wallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
            isAssociatedTokenUnregister = false
        } else {
            let destinationInfo = try await solanaAPIClient.findSPLTokenDestinationAddress(
                mintAddress: wallet.mintAddress,
                destinationAddress: receiver
            )
            isAssociatedTokenUnregister = destinationInfo.isUnregisteredAsocciatedToken
        }

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(context, payingTokenMint: payingTokenMint) {
            // subtract the fee payer signature cost
            transactionFee -= context.lamportsPerSignature
        }

        let expectedFee = FeeAmount(
            transaction: transactionFee,
            accountBalances: isAssociatedTokenUnregister ? context.minimumTokenAccountBalance : 0
        )

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(context, payingTokenMint: payingTokenMint) {
            return expectedFee
        }

        return try await feeRelayer.feeCalculator.calculateNeededTopUpAmount(
            context,
            expectedFee: expectedFee,
            payingTokenMint: try? PublicKey(string: payingTokenMint)
        )
    }

    func sendToSolanaBCViaRelayMethod(
        _ context: FeeRelayerContext,
        from wallet: Wallet,
        receiver: String,
        amount: Lamports,
        payingFeeWallet: Wallet?
    ) async throws -> String {
        // get paying fee token
        let payingFeeToken = try? getPayingFeeToken(payingFeeWallet: payingFeeWallet)

        let currency = wallet.mintAddress

        let (preparedTransaction, useFeeRelayer) = try await prepareForSendingToSolanaNetworkViaRelayMethod(
            context,
            from: wallet,
            receiver: receiver,
            amount: amount.convertToBalance(decimals: wallet.token.decimals),
            payingFeeToken: payingFeeToken
        )

        if useFeeRelayer {
            return try await feeRelayer.topUpAndRelayTransaction(
                context,
                preparedTransaction,
                fee: payingFeeToken,
                config: FeeRelayerConfiguration(
                    operationType: .transfer,
                    currency: currency
                )
            )
        } else {
            return try await blockchainClient.sendTransaction(preparedTransaction: preparedTransaction)
        }
    }

    private func prepareForSendingToSolanaNetworkViaRelayMethod(
        _ context: FeeRelayerContext,
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        payingFeeToken: FeeRelayerSwift.TokenAccount?,
        recentBlockhash: String? = nil,
        lamportsPerSignature: Lamports? = nil,
        minRentExemption: Lamports? = nil
    ) async throws -> (preparedTransaction: PreparedTransaction, useFeeRelayer: Bool) {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else { throw SolanaError.other("Source wallet is not valid") }
        // form request
        if receiver == sender {
            throw SolanaError.other(L10n.youCanNotSendTokensToYourself)
        }

        // prepare fee payer
        let feePayer: PublicKey?
        let useFeeRelayer: Bool

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
            context,
            payingTokenMint: payingFeeToken?.mint.base58EncodedString
        ) {
            feePayer = nil
            useFeeRelayer = false
        } else {
            feePayer = context.feePayerAddress
            useFeeRelayer = true
        }

        var preparedTransaction: PreparedTransaction
        if wallet.isNativeSOL {
            preparedTransaction = try await blockchainClient.prepareSendingNativeSOL(
                from: try accountStorage.account!,
                to: receiver,
                amount: amount,
                feePayer: feePayer
            )
        } else {
            preparedTransaction = try await blockchainClient.prepareSendingSPLTokens(
                account: accountStorage.account!,
                mintAddress: wallet.mintAddress,
                decimals: wallet.token.decimals,
                from: sender,
                to: receiver,
                amount: amount,
                feePayer: feePayer,
                transferChecked: useFeeRelayer, // create transferChecked instruction when using fee relayer
                lamportsPerSignature: lamportsPerSignature,
                minRentExemption: minRentExemption
            ).preparedTransaction
        }

        preparedTransaction.transaction.recentBlockhash = recentBlockhash
        return (preparedTransaction: preparedTransaction, useFeeRelayer: useFeeRelayer)
    }

    private func getPayingFeeToken(payingFeeWallet: Wallet?) throws -> FeeRelayerSwift.TokenAccount? {
        if let payingFeeWallet = payingFeeWallet {
            guard
                let addressString = payingFeeWallet.pubkey,
                let address = try? PublicKey(string: addressString),
                let mintAddress = try? PublicKey(string: payingFeeWallet.mintAddress)
            else {
                throw Error.invalidPayingFeeWallet
            }
            return .init(address: address, mint: mintAddress)
        }
        return nil
    }

    private func isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
        _ context: FeeRelayerContext,
        payingTokenMint: String?
    ) -> Bool {
        let expectedTransactionFee = (context.lamportsPerSignature ?? 5000) * 2
        return payingTokenMint == PublicKey.wrappedSOLMint.base58EncodedString &&
            context.usageStatus.isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }
}
