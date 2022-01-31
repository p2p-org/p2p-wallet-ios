//
//  SendTokenAPIClient.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation
import RxSwift
import FeeRelayerSwift

protocol SendTokenAPIClient {
    func getFees() -> Single<SolanaSDK.Fee>
    func checkAccountValidation(account: String) -> Single<Bool>
    func sendNativeSOL(
        to destination: String,
        amount: UInt64,
        withoutFee: Bool,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
    func sendSPLTokens(
        mintAddress: String,
        decimals: SolanaSDK.Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        withoutFee: Bool,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
    func isTestNet() -> Bool
}

extension SolanaSDK: SendTokenAPIClient {
    func sendNativeSOL(to destination: String, amount: UInt64, withoutFee: Bool, isSimulation: Bool) -> Single<TransactionID> {
        if withoutFee {
            let feeRelayerAPIClient = FeeRelayer.APIClient(version: 1)
            
            return feeRelayerAPIClient.getFeePayerPubkey()
                .flatMap { [weak self] feePayer -> Single<SolanaSDK.PreparedTransaction> in
                    guard let self = self else {return .error(SolanaSDK.Error.unknown)}
                    let feePayer = try SolanaSDK.PublicKey(string: feePayer)
                    return self.prepareSendingNativeSOL(to: destination, amount: amount, feePayer: feePayer)
                }
                .flatMap { [weak self] preparedTransaction in
                    guard let self = self, let blockhash = preparedTransaction.transaction.recentBlockhash else {return .error(SolanaSDK.Error.unknown)}
                    guard let account = self.accountStorage.account else {return .error(SolanaSDK.Error.unauthorized)}
                    let signature = try preparedTransaction.findSignature(publicKey: account.publicKey)
                    return feeRelayerAPIClient.sendTransactionAndLog(
                        .transferSOL(
                            .init(
                                sender: account.publicKey.base58EncodedString,
                                recipient: destination,
                                amount: amount,
                                signature: signature,
                                blockhash: blockhash
                            )
                        )
                    )
                }
        } else {
            return sendNativeSOL(to: destination, amount: amount, isSimulation: isSimulation)
        }
    }
    
    func sendSPLTokens(mintAddress: String, decimals: Decimals, from fromPublicKey: String, to destinationAddress: String, amount: UInt64, withoutFee: Bool, isSimulation: Bool) -> Single<TransactionID> {
        if withoutFee {
            let feeRelayerAPIClient = FeeRelayer.APIClient(version: 1)
            
            return feeRelayerAPIClient.getFeePayerPubkey()
                .flatMap { [weak self] feePayer -> Single<(preparedTransaction: PreparedTransaction, realDestination: String)> in
                    guard let self = self else {return .error(SolanaSDK.Error.unknown)}
                    let feePayer = try SolanaSDK.PublicKey(string: feePayer)
                    return self.prepareSendingSPLTokens(
                        mintAddress: mintAddress,
                        decimals: decimals,
                        from: fromPublicKey,
                        to: destinationAddress,
                        amount: amount,
                        feePayer: feePayer,
                        transferChecked: true
                    )
                }
                .flatMap { [weak self] result in
                    let preparedTransaction = result.preparedTransaction
                    let realDestination = result.realDestination
                    guard let self = self, let blockhash = preparedTransaction.transaction.recentBlockhash else {return .error(SolanaSDK.Error.unknown)}
                    guard let account = self.accountStorage.account else {return .error(SolanaSDK.Error.unauthorized)}
                    let signature = try preparedTransaction.findSignature(publicKey: account.publicKey)
                    return feeRelayerAPIClient.sendTransactionAndLog(
                        .transferSPLToken(
                            .init(
                                sender: fromPublicKey,
                                recipient: realDestination,
                                mintAddress: mintAddress,
                                authority: account.publicKey.base58EncodedString,
                                amount: amount,
                                decimals: decimals,
                                signature: signature,
                                blockhash: blockhash
                            )
                        )
                    )
                }
        } else {
            return sendSPLTokens(
                mintAddress: mintAddress,
                decimals: decimals,
                from: fromPublicKey,
                to: destinationAddress,
                amount: amount,
                isSimulation: isSimulation
            )
        }
    }
    
    func getFees() -> Single<Fee> {
        getFees(commitment: nil)
    }
    
    func isTestNet() -> Bool {
        endpoint.network.isTestnet
    }
}

private extension FeeRelayer.APIClient {
    func sendTransactionAndLog(_ requestType: FeeRelayer.RequestType) -> Single<SolanaSDK.TransactionID> {
        // log request
        if let data = try? requestType.getParams(),
           let message = String(data: data, encoding: .utf8)
        {
            Logger.log(message: message, event: .request)
        }
        
        // send
        return sendTransaction(requestType)
            .map {$0.replacingOccurrences(of: "\"", with: "")}
            .do(onSuccess: {
                Logger.log(message: "\($0)", event: .response)
            }, onError: {
                Logger.log(message: "\($0)", event: .error)
            })
    }
}
