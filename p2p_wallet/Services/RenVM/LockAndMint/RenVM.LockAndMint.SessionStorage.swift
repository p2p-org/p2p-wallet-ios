//
//  RenVM.LockAndMint.SessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation

extension RenVM.LockAndMint {
    struct ProcessingTx: Codable {
        let tx: TxDetail
        var isMinted: Bool
    }
}

protocol RenVMLockAndMintSessionStorageType {
    func loadSession() -> RenVM.Session?
    func saveSession(_ session: RenVM.Session)
    func expireCurrentSession()
    
    func isMinted(txid: String) -> Bool
    func isSubmited(txid: String) -> Bool
    func setAsMinted(tx: RenVM.LockAndMint.TxDetail)
    func setAsSubmited(tx: RenVM.LockAndMint.TxDetail)
    func getSubmitedButUnmintedTxId() -> [RenVM.LockAndMint.TxDetail]
}

extension RenVM.LockAndMint {
    struct SessionStorage: RenVMLockAndMintSessionStorageType {
        func loadSession() -> RenVM.Session? {
            Defaults.renVMSession
        }
        
        func saveSession(_ session: RenVM.Session) {
            Defaults.renVMSession = session
        }
        
        func expireCurrentSession() {
            Defaults.renVMSession = nil
            Defaults.renVMProcessingTxs = []
        }
        
        func isMinted(txid: String) -> Bool {
            Defaults.renVMProcessingTxs.first(where: {$0.tx.txid == txid})?.isMinted == true
        }
        
        func isSubmited(txid: String) -> Bool {
            Defaults.renVMProcessingTxs.contains(where: {$0.tx.txid == txid})
        }
        
        func setAsMinted(tx: TxDetail) {
            var txs = Defaults.renVMProcessingTxs
            
            if let index = txs.firstIndex(where: {$0.tx.txid == tx.txid}) {
                var tx = txs[index]
                tx.isMinted = true
                txs[index] = tx
            }
            
            Defaults.renVMProcessingTxs = txs
        }
        
        func setAsSubmited(tx: TxDetail) {
            if Defaults.renVMProcessingTxs.contains(where: {$0.tx.txid == tx.txid}) {return}
            var txs = Defaults.renVMProcessingTxs
            txs.append(.init(tx: tx, isMinted: false))
            Defaults.renVMProcessingTxs = txs
        }
        
        func getSubmitedButUnmintedTxId() -> [TxDetail] {
            Defaults.renVMProcessingTxs.filter {$0.isMinted == false}.map {$0.tx}
        }
    }
}
