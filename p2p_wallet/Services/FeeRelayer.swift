//
//  FeeRelayer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/07/2021.
//

import Foundation
import RxSwift
import FeeRelayerSwift

private extension FeeRelayer.Compensation.SwapTokensParamsSwapAccount {
    init(
        pool: SolanaSDK.Pool,
        transferAuthority: String,
        amountIn: FeeRelayer.Lamports,
        minAmountOut: FeeRelayer.Lamports
    ) {
        self.init(
            pubkey: pool.address.base58EncodedString,
            authority: pool.authority?.base58EncodedString ?? "",
            transferAuthority: transferAuthority,
            source: pool.swapData.tokenAccountA.base58EncodedString,
            destination: pool.swapData.tokenAccountB.base58EncodedString,
            poolTokenMint: pool.swapData.tokenPool.base58EncodedString,
            poolFeeAccount: pool.swapData.feeAccount.base58EncodedString,
            amountIn: amountIn,
            minimumAmountOut: minAmountOut
        )
    }
}

extension FeeRelayer.APIClient: SolanaCustomFeeRelayerProxy {
    public func getFeePayer() -> Single<String> {
        getFeePayerPubkey()
    }
    
    public func transferSOL(
        sender: String,
        recipient: String,
        amount: SolanaSDK.Lamports,
        signature: String,
        blockhash: String,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID> {
        sendTransactionAndLog(
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
    
    public func transferSPLToken(
        sender: String,
        recipient: String,
        mintAddress: String,
        authority: String,
        amount: SolanaSDK.Lamports,
        decimals: SolanaSDK.Decimals,
        signature: String,
        blockhash: String
    ) -> Single<SolanaSDK.TransactionID> {
        sendTransactionAndLog(
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
    
    public func swapToken(
        sourceToken: String,
        destinationToken: String,
        sourceTokenMint: String,
        destinationTokenMint: String,
        userAuthority: String,
        pool: SolanaSDK.Pool,
        amount: SolanaSDK.Lamports,
        minAmountOut: SolanaSDK.Lamports,
        feeCompensationPool: SolanaSDK.Pool,
        feeAmount: SolanaSDK.Lamports,
        feeMinAmountOut: SolanaSDK.Lamports,
        feePayerWSOLAccountKeypair: String,
        signature: String,
        blockhash: String
    ) -> Single<SolanaSDK.TransactionID> {
        sendTransactionAndLog(
            .swapToken(
                .init(
                    source: sourceToken,
                    sourceMint: sourceTokenMint,
                    destination: destinationToken,
                    destinationMint: destinationTokenMint,
                    authority: userAuthority,
                    swapAccount: .init(
                        pool: pool,
                        transferAuthority: userAuthority,
                        amountIn: amount,
                        minAmountOut: minAmountOut
                    ),
                    feeCompensationSwapAccount: .init(
                        pool: feeCompensationPool,
                        transferAuthority: userAuthority,
                        amountIn: feeAmount,
                        minAmountOut: feeMinAmountOut
                    ),
                    feePayerWSOLAccountKeypair: feePayerWSOLAccountKeypair,
                    signature: signature,
                    blockhash: blockhash
                )
            )
        )
    }
    
    private func sendTransactionAndLog(_ requestType: FeeRelayer.RequestType) -> Single<SolanaSDK.TransactionID> {
        // log request
        if let data = try? requestType.getParams(),
           let message = String(data: data, encoding: .utf8)
        {
            Logger.log(message: message, event: .request)
        }
        
        // send
        return sendTransaction(requestType)
            .do(onSuccess: {
                Logger.log(message: "\($0)", event: .response)
            }, onError: {
                Logger.log(message: "\($0)", event: .error)
            })
    }
}
