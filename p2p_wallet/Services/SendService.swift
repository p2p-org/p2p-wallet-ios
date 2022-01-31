//
//  SendServiceType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation
import RxSwift
import FeeRelayerSwift
import OrcaSwapSwift

protocol SendServiceType {
    func load() -> Completable
    func getFees() -> Single<SolanaSDK.Fee>
    func checkAccountValidation(account: String) -> Single<Bool>
    func sendNativeSOL(
        to destination: String,
        amount: UInt64,
        payingFeeToken: FeeRelayer.Relay.TokenInfo?,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
    func sendSPLTokens(
        mintAddress: String,
        decimals: SolanaSDK.Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        payingFeeToken: FeeRelayer.Relay.TokenInfo?,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
    func isTestNet() -> Bool
}

class SendService: SendServiceType {
    @Injected private var solanaSDK: SolanaSDK
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var feeRelayerAPIClient: FeeRelayerAPIClientType
    @Injected private var relayService: FeeRelayerRelayType
    
    func load() -> Completable {
        orcaSwap.load()
            .andThen(relayService.load())
    }
    
    func getFees() -> Single<SolanaSDK.Fee> {
        solanaSDK.getFees(commitment: nil)
    }
    
    func checkAccountValidation(account: String) -> Single<Bool> {
        solanaSDK.checkAccountValidation(account: account)
    }
    
    func sendNativeSOL(
        to destination: String,
        amount: UInt64,
        payingFeeToken: FeeRelayer.Relay.TokenInfo?,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID> {
        // fee relayer
        if let payingFeeToken = payingFeeToken,
           payingFeeToken.mint != SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
        {
            return feeRelayerAPIClient.getFeePayerPubkey()
                .flatMap { [weak self] feePayer -> Single<SolanaSDK.PreparedTransaction> in
                    guard let self = self else {return .error(SolanaSDK.Error.unknown)}
                    let feePayer = try SolanaSDK.PublicKey(string: feePayer)
                    return self.solanaSDK.prepareSendingNativeSOL(to: destination, amount: amount, feePayer: feePayer)
                }
                .flatMap { [weak self] preparedTransaction in
                    guard let self = self else { throw SolanaSDK.Error.unknown }
                    return self.relayService.topUpAndRelayTransaction(
                        preparedTransaction: preparedTransaction,
                        payingFeeToken: payingFeeToken
                    )
                        .map {$0.first ?? ""}
                }
                .do(onSuccess: {
                    Logger.log(message: "\($0)", event: .response)
                }, onError: {
                    Logger.log(message: "\($0)", event: .error)
                })
        }
        // no fee relayer
        else {
            return solanaSDK.sendNativeSOL(to: destination, amount: amount, isSimulation: isSimulation)
        }
    }
    
    func sendSPLTokens(
        mintAddress: String,
        decimals: SolanaSDK.Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        payingFeeToken: FeeRelayer.Relay.TokenInfo?,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID> {
        // fee relayer
        if let payingFeeToken = payingFeeToken,
           payingFeeToken.mint != SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
        {
            return feeRelayerAPIClient.getFeePayerPubkey()
                .flatMap { [weak self] feePayer -> Single<(preparedTransaction: SolanaSDK.PreparedTransaction, realDestination: String)> in
                    guard let self = self else {return .error(SolanaSDK.Error.unknown)}
                    let feePayer = try SolanaSDK.PublicKey(string: feePayer)
                    return self.solanaSDK.prepareSendingSPLTokens(
                        mintAddress: mintAddress,
                        decimals: decimals,
                        from: fromPublicKey,
                        to: destinationAddress,
                        amount: amount,
                        feePayer: feePayer,
                        transferChecked: true
                    )
                }
                .flatMap { [weak self] params in
                    guard let self = self else { throw SolanaSDK.Error.unknown }
                    let preparedTransaction = params.preparedTransaction
//                    let realDestination = params.realDestination
                    return self.relayService.topUpAndRelayTransaction(
                        preparedTransaction: preparedTransaction,
                        payingFeeToken: payingFeeToken
                    )
                        .map {$0.first ?? ""}
                }
                .do(onSuccess: {
                    Logger.log(message: "\($0)", event: .response)
                }, onError: {
                    Logger.log(message: "\($0)", event: .error)
                })
        } else {
            return solanaSDK.sendSPLTokens(
                mintAddress: mintAddress,
                decimals: decimals,
                from: fromPublicKey,
                to: destinationAddress,
                amount: amount,
                isSimulation: isSimulation
            )
        }
    }
    
    func isTestNet() -> Bool {
        solanaSDK.endpoint.network.isTestnet
    }
}
