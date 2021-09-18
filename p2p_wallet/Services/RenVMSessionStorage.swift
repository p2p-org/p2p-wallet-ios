//
//  RenVMSessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation

extension RenVM {
    struct SubmitedTx: Codable {
        let tx: TxDetail
        var isMinted: Bool
    }
}

protocol RenVMSessionStorageType {
    func loadSession() -> RenVM.Session?
    func saveSession(_ session: RenVM.Session)
    func expireCurrentSession()
    
    func isMinted(txid: String) -> Bool
    func isSubmited(txid: String) -> Bool
    func setAsMinted(tx: RenVM.TxDetail)
    func setAsSubmited(tx: RenVM.TxDetail)
    func getSubmitedButUnmintedTxId() -> [RenVM.TxDetail]
}

struct RenVMSessionStorage: RenVMSessionStorageType {
    func loadSession() -> RenVM.Session? {
        Defaults.renVMSession
    }
    
    func saveSession(_ session: RenVM.Session) {
        Defaults.renVMSession = session
    }
    
    func expireCurrentSession() {
        Defaults.renVMSession = nil
        Defaults.renVMSubmitedTxDetail = []
    }
    
    func isMinted(txid: String) -> Bool {
        Defaults.renVMSubmitedTxDetail.first(where: {$0.tx.txid == txid})?.isMinted == true
    }
    
    func isSubmited(txid: String) -> Bool {
        Defaults.renVMSubmitedTxDetail.contains(where: {$0.tx.txid == txid})
    }
    
    func setAsMinted(tx: RenVM.TxDetail) {
        var txs = Defaults.renVMSubmitedTxDetail
        
        if let index = txs.firstIndex(where: {$0.tx.txid == tx.txid}) {
            var tx = txs[index]
            tx.isMinted = true
            txs[index] = tx
        }
        
        Defaults.renVMSubmitedTxDetail = txs
    }
    
    func setAsSubmited(tx: RenVM.TxDetail) {
        if Defaults.renVMSubmitedTxDetail.contains(where: {$0.tx.txid == tx.txid}) {return}
        var txs = Defaults.renVMSubmitedTxDetail
        txs.append(.init(tx: tx, isMinted: false))
        Defaults.renVMSubmitedTxDetail = txs
    }
    
    func getSubmitedButUnmintedTxId() -> [RenVM.TxDetail] {
        Defaults.renVMSubmitedTxDetail.filter {$0.isMinted == false}.map {$0.tx}
    }
}
