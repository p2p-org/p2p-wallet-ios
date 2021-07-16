//
//  FeeRelayer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/07/2021.
//

import Foundation
import RxSwift
import FeeRelayerSwift

protocol FeeRelayerType {
    func getFeePayerPubkey() -> Single<String>
}

extension FeeRelayer: FeeRelayerType, SolanaCustomFeeRelayerProxy {
    public func getFeePayer() -> Single<String> {
        getFeePayerPubkey()
    }
    
    public func transferSOL(sender: String, recipient: String, amount: SolanaSDK.Lamports, signature: String, blockhash: String, isSimulation: Bool) -> Single<SolanaSDK.TransactionID> {
        sendTransaction(
            .transferSOL(
                .init(
                    sender: sender,
                    recipient: recipient,
                    amount: amount,
                    signature: signature,
                    blockhash: blockhash
                )
            )
        )
    }
    
    public func transferSPLToken(sender: String, recipient: String, mintAddress: String, authority: String, amount: SolanaSDK.Lamports, decimals: SolanaSDK.Decimals, signature: String, blockhash: String) -> Single<SolanaSDK.TransactionID> {
        sendTransaction(
            .transferSPLToken(
                .init(
                    sender: sender,
                    recipient: recipient,
                    mintAddress: mintAddress,
                    authority: authority,
                    amount: amount,
                    decimals: decimals,
                    signature: signature,
                    blockhash: blockhash
                )
            )
        )
    }
}
