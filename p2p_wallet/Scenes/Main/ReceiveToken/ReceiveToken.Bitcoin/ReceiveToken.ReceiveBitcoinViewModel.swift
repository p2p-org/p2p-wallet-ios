//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveTokenBitcoinViewModelType {
    var isLoadingDriver: Driver<Bool> {get}
    var addressDriver: Driver<String?> {get}
    
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
        private let sessionStorage: RenVMSessionStorageType
        
        private var lockAndMint: RenVM.LockAndMint?
        
        // MARK: - Subjects
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        private let addressSubject = BehaviorRelay<String?>(value: nil)
        
        // MARK: - Initializers
        init(
            rpcClient: RenVMRpcClientType,
            solanaClient: RenVMSolanaAPIClientType,
            destinationAddress: SolanaSDK.PublicKey,
            sessionStorage: RenVMSessionStorageType
        ) {
            self.rpcClient = rpcClient
            self.solanaClient = solanaClient
            self.destinationAddress = destinationAddress
            self.sessionStorage = sessionStorage
        }
        
        func reload() {
            // if session exist, restore the session, load address
            if let session = sessionStorage.loadSession() {
                loadAddress()
            }
            
            // if not create session, load address
            else {
                
            }
        }
        
        private func loadAddress() {
            isLoadingSubject.accept(true)
        }
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }
    
    var addressDriver: Driver<String?> {
        addressSubject.asDriver()
    }
}
