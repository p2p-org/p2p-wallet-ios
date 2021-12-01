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
        sendNativeSOL(
            to: destination,
            amount: amount,
            isSimulation: isSimulation,
            customProxy: withoutFee ? FeeRelayer(): nil
        )
    }
    
    func sendSPLTokens(mintAddress: String, decimals: Decimals, from fromPublicKey: String, to destinationAddress: String, amount: UInt64, withoutFee: Bool, isSimulation: Bool) -> Single<TransactionID> {
        sendSPLTokens(
            mintAddress: mintAddress,
            decimals: decimals,
            from: fromPublicKey,
            to: destinationAddress,
            amount: amount,
            isSimulation: isSimulation,
            customProxy: withoutFee ? FeeRelayer(): nil
        )
    }
    
    func getFees() -> Single<Fee> {
        getFees(commitment: nil)
    }
    
    func isTestNet() -> Bool {
        endpoint.network.isTestnet
    }
}
