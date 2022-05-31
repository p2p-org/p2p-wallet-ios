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
        from _: Wallet,
        receiver _: String,
        payingTokenMint _: String?
    ) -> Single<SolanaSDK.FeeAmount?> {
        // TODO: fix
        fatalError("Method has not been implemented")

        // // get fee calculator
        // guard let lamportsPerSignature = relayService.cache.lamportsPerSignature,
        //       let minRentExemption = relayService.cache.minimumTokenAccountBalance
        // else { return .error(FeeRelayer.Error.unknown) }
        //
        // var transactionFee: UInt64 = 0
        //
        // // owner's signature
        // transactionFee += lamportsPerSignature
        //
        // // feePayer's signature
        // transactionFee += lamportsPerSignature
        //
        // let isUnregisteredAsocciatedTokenRequest: Single<Bool>
        // if wallet.mintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
        //     isUnregisteredAsocciatedTokenRequest = .just(false)
        // } else {
        //     isUnregisteredAsocciatedTokenRequest = solanaSDK.findSPLTokenDestinationAddress(
        //         mintAddress: wallet.mintAddress,
        //         destinationAddress: receiver
        //     )
        //         .map(\.isUnregisteredAsocciatedToken)
        // }
        //
        // // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        // if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(payingTokenMint: payingTokenMint) {
        //     // subtract the fee payer signature cost
        //     transactionFee -= lamportsPerSignature
        // }
        //
        // return isUnregisteredAsocciatedTokenRequest
        //     .map {
        //         SolanaSDK.FeeAmount(
        //             transaction: transactionFee,
        //             accountBalances: $0 ? minRentExemption : 0
        //         )
        //     }
        //     .flatMap { [weak self] expectedFee in
        //         guard let self = self else { throw SolanaSDK.Error.unknown }
        //
        //         // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        //         if self.isFreeTransactionNotAvailableAndUserIsPayingWithSOL(payingTokenMint: payingTokenMint) {
        //             return .just(expectedFee)
        //         }
        //
        //         return self.relayService.calculateNeededTopUpAmount(
        //             expectedFee: expectedFee,
        //             payingTokenMint: payingTokenMint
        //         )
        //             .map(Optional.init)
        //     }
    }

    func sendToSolanaBCViaRelayMethod(
        from _: Wallet,
        receiver _: String,
        amount _: SolanaSDK.Lamports,
        payingFeeWallet _: Wallet?
    ) -> Single<String> {
        // TODO: fix
        fatalError("Method has not been implemented")

        // // get paying fee token
        // let payingFeeToken = try? getPayingFeeToken(payingFeeWallet: payingFeeWallet)
        //
        // let currency = wallet.mintAddress
        //
        // return prepareForSendingToSolanaNetworkViaRelayMethod(
        //     from: wallet,
        //     receiver: receiver,
        //     amount: amount.convertToBalance(decimals: wallet.token.decimals),
        //     payingFeeToken: payingFeeToken
        // )
        //     .flatMap { [weak self] preparedTransaction, useFeeRelayer in
        //         guard let self = self else { throw SolanaSDK.Error.unknown }
        //
        //         if useFeeRelayer {
        //             // using fee relayer
        //             return self.relayService.topUpAndRelayTransaction(
        //                 preparedTransaction: preparedTransaction,
        //                 payingFeeToken: payingFeeToken,
        //                 operationType: .transfer,
        //                 currency: currency
        //             )
        //                 .map { $0.first ?? "" }
        //         } else {
        //             // send normally, paid by SOL
        //             return self.solanaSDK.serializeAndSend(
        //                 preparedTransaction: preparedTransaction,
        //                 isSimulation: false
        //             )
        //         }
        //     }
        //     .do(onSuccess: {
        //         Logger.log(message: "\($0)", event: .response)
        //     }, onError: {
        //         Logger.log(message: "\($0)", event: .error)
        //     })
    }

    private func prepareForSendingToSolanaNetworkViaRelayMethod(
        from _: Wallet,
        receiver _: String,
        amount _: Double,
        payingFeeToken _: FeeRelayerSwift.TokenAccount?,
        recentBlockhash _: String? = nil,
        lamportsPerSignature _: SolanaSDK.Lamports? = nil,
        minRentExemption _: SolanaSDK.Lamports? = nil,
        usingCachedFeePayerPubkey _: Bool = false
    ) -> Single<(preparedTransaction: SolanaSDK.PreparedTransaction, useFeeRelayer: Bool)> {
        fatalError("Method has not been implemented")

        // TODO: fix
        // let amount = amount.toLamport(decimals: wallet.token.decimals)
        // guard let sender = wallet.pubkey else { return .error(SolanaSDK.Error.other("Source wallet is not valid")) }
        // // form request
        // if receiver == sender {
        //     return .error(SolanaSDK.Error.other(L10n.youCanNotSendTokensToYourself))
        // }
        //
        // // prepare fee payer
        // let feePayerRequest: Single<String?>
        // let useFeeRelayer: Bool
        //
        // // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        // if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(payingTokenMint: payingFeeToken?.mint) {
        //     feePayerRequest = .just(nil)
        //     useFeeRelayer = false
        // }
        //
        // // otherwise send to fee relayer
        // else {
        //     if usingCachedFeePayerPubkey, let pubkey = cachedFeePayerPubkey {
        //         feePayerRequest = .just(pubkey)
        //     } else {
        //         feePayerRequest = feeRelayerAPIClient.getFeePayerPubkey()
        //             .map(Optional.init)
        //             .do(onSuccess: { [weak self] in self?.cachedFeePayerPubkey = $0 })
        //     }
        //     useFeeRelayer = true
        // }
        //
        // return feePayerRequest
        //     .flatMap { [weak self] feePayer in
        //         guard let self = self else { return .error(SolanaSDK.Error.unknown) }
        //         let feePayer = feePayer == nil ? nil : try SolanaSDK.PublicKey(string: feePayer)
        //
        //         let request: Single<SolanaSDK.PreparedTransaction>
        //         if wallet.isNativeSOL {
        //             request = self.solanaSDK.prepareSendingNativeSOL(
        //                 to: receiver,
        //                 amount: amount,
        //                 feePayer: feePayer,
        //                 recentBlockhash: recentBlockhash,
        //                 lamportsPerSignature: lamportsPerSignature
        //             )
        //         }
        //
        //         // other tokens
        //         else {
        //             request = self.solanaSDK.prepareSendingSPLTokens(
        //                 mintAddress: wallet.mintAddress,
        //                 decimals: wallet.token.decimals,
        //                 from: sender,
        //                 to: receiver,
        //                 amount: amount,
        //                 feePayer: feePayer,
        //                 transferChecked: useFeeRelayer, // create transferChecked instruction when using fee relayer
        //                 recentBlockhash: recentBlockhash,
        //                 lamportsPerSignature: lamportsPerSignature,
        //                 minRentExemption: minRentExemption
        //             ).map(\.preparedTransaction)
        //         }
        //
        //         return request.map { (preparedTransaction: $0, useFeeRelayer: useFeeRelayer) }
        //     }
    }

    private func getPayingFeeToken(payingFeeWallet _: Wallet?) throws -> FeeRelayerSwift.TokenAccount? {
        fatalError("Method has not been implemented")

        // if let payingFeeWallet = payingFeeWallet {
        //     guard let address = payingFeeWallet.pubkey else {
        //         throw SolanaSDK.Error.other("Paying fee wallet is not valid")
        //     }
        //     return .init(address: address, mint: payingFeeWallet.mintAddress)
        // }
        // return nil
    }

    private func isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
        payingTokenMint _: String?
    ) -> Bool {
        fatalError("Method has not been implemented")

        // let expectedTransactionFee = (relayService.cache.lamportsPerSignature ?? 5000) * 2
        // return payingTokenMint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString &&
        //     relayService.cache.freeTransactionFeeLimit?
        //     .isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }
}
