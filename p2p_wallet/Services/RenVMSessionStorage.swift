//
//  RenVMSessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation

extension RenVM {
    struct Tx: Codable {
        let txid: String
        var status: Status
        
        enum Status: Int, Comparable, Equatable, Codable {
            static func < (lhs: Status, rhs: Status) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
            
            case submiting = 0, submited, minting, minted
            var isProcessing: Bool {
                self == .submiting || self == .minting
            }
        }
    }
}

protocol RenVMSessionStorageType {
    func loadSession() -> RenVM.Session?
    func saveSession(_ session: RenVM.Session)
    func expireCurrentSession()
    
    func setStatusFor(_ txid: String, status: RenVM.Tx.Status?)
    func getStatusFor(_ txid: String) -> RenVM.Tx.Status?
}

struct RenVMSessionStorage: RenVMSessionStorageType {
    func getStatusFor(_ txid: String) -> RenVM.Tx.Status? {
        Defaults.renVMTxs.first(where: {$0.txid == txid})?.status
    }
    
    func setStatusFor(_ txid: String, status: RenVM.Tx.Status?) {
        var txs = Defaults.renVMTxs
        
        if let status = status {
            if let index = txs.firstIndex(where: {$0.txid == txid}) {
                var tx = txs[index]
                tx.status = status
                txs[index] = tx
            }
        } else {
            txs.removeAll(where: {$0.txid == txid})
        }
        
        Defaults.renVMTxs = txs
    }
    
    func loadSession() -> RenVM.Session? {
        Defaults.renVMSession
    }
    
    func saveSession(_ session: RenVM.Session) {
        Defaults.renVMSession = session
    }
    
    func expireCurrentSession() {
        Defaults.renVMSession = nil
    }
}
