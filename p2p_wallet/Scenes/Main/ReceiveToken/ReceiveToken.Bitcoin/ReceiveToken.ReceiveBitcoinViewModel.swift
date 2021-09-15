//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxCocoa

protocol ReceiveTokenBitcoinViewModelType {
    var initialStateDriver: Driver<LoadableState> {get}
    
    func reload()
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
        
        // MARK: - Subjects
        private let solanaChainSubject: LoadableRelay<RenVM.SolanaChain>
        private var lockAndMint: RenVM.LockAndMint?
        
        // MARK: - Initializers
        init(
            rpcClient: RenVMRpcClientType,
            solanaClient: RenVMSolanaAPIClientType,
            destinationAddress: SolanaSDK.PublicKey
        ) {
            self.rpcClient = rpcClient
            self.solanaClient = solanaClient
            self.destinationAddress = destinationAddress
            
            self.solanaChainSubject = .init(
                request: RenVM.SolanaChain.load(
                    client: rpcClient,
                    solanaClient: solanaClient,
                    network: rpcClient.network
                )
            )
            
            bind()
            
            // check if session exist
            
            // if session exist, restore the session
            
            // if not create session
        }
        
        func bind() {
            
        }
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    var initialStateDriver: Driver<LoadableState> {
        solanaChainSubject.stateObservable
            .asDriver(onErrorJustReturn: .notRequested)
    }
    
    func reload() {
        solanaChainSubject.reload()
    }
}
