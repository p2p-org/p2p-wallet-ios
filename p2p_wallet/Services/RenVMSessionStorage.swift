//
//  RenVMSessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation

extension RenVM {
    struct SubmitedTx: Codable {
        let txid: String
        var isMinted: Bool
    }
}

protocol RenVMSessionStorageType {
    func loadSession() -> RenVM.Session?
    func saveSession(_ session: RenVM.Session)
    func expireCurrentSession()
    
    func isMinted(txid: String) -> Bool
    func isSubmited(txid: String) -> Bool
    func setAsMinted(txid: String)
    func setAsSubmited(txid: String)
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
    }
    
    func isMinted(txid: String) -> Bool {
        Defaults.renVMSubmitedTx.first(where: {$0.txid == txid})?.isMinted == true
    }
    
    func isSubmited(txid: String) -> Bool {
        Defaults.renVMSubmitedTx.contains(where: {$0.txid == txid})
    }
    
    func setAsMinted(txid: String) {
        var txs = Defaults.renVMSubmitedTx
        
        if let index = txs.firstIndex(where: {$0.txid == txid}) {
            var tx = txs[index]
            tx.isMinted = true
            txs[index] = tx
        }
        
        Defaults.renVMSubmitedTx = txs
    }
    
    func setAsSubmited(txid: String) {
        if Defaults.renVMSubmitedTx.contains(where: {$0.txid == txid}) {return}
        var txs = Defaults.renVMSubmitedTx
        txs.append(.init(txid: txid, isMinted: false))
        Defaults.renVMSubmitedTx = txs
    }
}
