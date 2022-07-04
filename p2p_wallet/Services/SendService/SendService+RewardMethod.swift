//
//  SendService+RewardMethod.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2022.
//

import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

extension SendService {
    func sendToSolanaBCViaRewardMethod(
        _ context: FeeRelayerContext,
        from wallet: Wallet,
        receiver: String,
        amount: Lamports
    ) async throws -> String {
        guard
            let owner = accountStorage.account,
            let sender = wallet.pubkey
        else {
            throw SolanaError.unauthorized
        }

        let recentBlockhash: String = try await solanaAPIClient.getRecentBlockhash(commitment: nil)

        let info = try await prepareForSendingToSolanaNetworkViaRewardMethod(
            context,
            from: wallet,
            receiver: receiver,
            amount: amount.convertToBalance(decimals: wallet.token.decimals),
            recentBlockhash: recentBlockhash
        )

        guard let data = info.0.transaction.findSignature(pubkey: owner.publicKey)?.signature else {
            throw SolanaError.other("Signature not found")
        }

        let authoritySignature = Base58.encode(data.bytes)

        let id: String
        if wallet.isNativeSOL {
            id = try await feeRelayerAPIClient.sendTransaction(
                .rewardTransferSOL(
                    .init(
                        sender: sender,
                        recipient: receiver,
                        amount: amount,
                        signature: authoritySignature,
                        blockhash: recentBlockhash,
                        deviceType: .iOS,
                        buildNumber: Bundle.main.fullVersionNumber
                    )
                )
            )
        } else {
            id = try await feeRelayerAPIClient.sendTransaction(
                .rewardTransferSPLToken(
                    .init(
                        sender: sender,
                        recipient: info.1!,
                        mintAddress: wallet.mintAddress,
                        authority: owner.publicKey.base58EncodedString,
                        amount: amount,
                        decimals: wallet.token.decimals,
                        signature: authoritySignature,
                        blockhash: recentBlockhash,
                        deviceType: .iOS,
                        buildNumber: Bundle.main.fullVersionNumber
                    )
                )
            )
        }

        return id.replacingOccurrences(of: "\"", with: "")
    }

    private func prepareForSendingToSolanaNetworkViaRewardMethod(
        _ context: FeeRelayerContext,
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        recentBlockhash: String? = nil
    ) async throws -> (PreparedTransaction, String?) {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else { throw SolanaError.other("Source wallet is not valid") }

        // form request
        if receiver == sender {
            throw SolanaError.other(L10n.youCanNotSendTokensToYourself)
        }

        // prepare fee payer
        let feePayer = context.feePayerAddress

        if wallet.isNativeSOL {
            let preparedTrx = try await blockchainClient.prepareSendingNativeSOL(
                from: accountStorage.account!,
                to: receiver,
                amount: amount,
                feePayer: feePayer
            )
            return (preparedTrx, nil)
        } else {
            var info = try await blockchainClient.prepareSendingSPLTokens(
                account: accountStorage.account!,
                mintAddress: wallet.mintAddress,
                decimals: wallet.token.decimals,
                from: sender,
                to: receiver,
                amount: amount,
                feePayer: feePayer,
                transferChecked: true // create transferChecked instruction when using fee relayer
            )
            info.preparedTransaction.transaction.recentBlockhash = recentBlockhash
            return info
        }
    }
}
