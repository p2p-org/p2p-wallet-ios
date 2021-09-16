//
//  RenVMSessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation

protocol RenVMSessionStorageType {
    func loadSession() -> RenVM.Session?
    func saveSession(_ session: RenVM.Session)
    func expireCurrentSession()
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
}
