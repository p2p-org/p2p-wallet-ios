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
    func checkNameOrAccountValidation(nameOrAccount: String, nameService: NameServiceType) -> Single<Bool>
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
}

extension SolanaSDK: SendTokenAPIClient {
    func checkNameOrAccountValidation(nameOrAccount: String, nameService: NameServiceType) -> Single<Bool> {
        if nameOrAccount.hasSuffix(.nameServiceDomain) {
            return nameService.getOwnerAddress(
                nameOrAccount.replacingOccurrences(
                    of: String.nameServiceDomain,
                    with: ""
                )
            ).map {$0 != nil}
        } else {
            return checkAccountValidation(account: nameOrAccount)
        }
    }
    
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
}
