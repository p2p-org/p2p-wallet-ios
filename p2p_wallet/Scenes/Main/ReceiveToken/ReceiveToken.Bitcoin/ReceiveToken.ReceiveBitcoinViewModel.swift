//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation

protocol ReceiveTokenBitcoinViewModelType {
    
}

extension ReceiveToken {
    class ReceiveBitcoinViewModel {
        // MARK: - Constants
        private let mintTokenSymbol = "BTC"
        private let version = "1"
        
        // MARK: - Properties
        private let rpcClient: RenVMRpcClientType
        private let solanaClient: RenVMSolanaAPIClientType
        private let destinationAddress: SolanaSDK.PublicKey
        
        // MARK: - Initializers
        init(
            rpcClient: RenVMRpcClientType,
            solanaClient: RenVMSolanaAPIClientType,
            destinationAddress: SolanaSDK.PublicKey
        ) {
            self.rpcClient = rpcClient
            self.solanaClient = solanaClient
            self.destinationAddress = destinationAddress
            
            // load solana chain
            
            // configure lock and mint
            
//            self.lockAndMint = .init(
//                rpcClient: rpcClient,
//                chain: chain,
//                mintTokenSymbol: mintTokenSymbol,
//                version: version,
//                destinationAddress: destinationAddress.data
//            )
        }
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    
}
