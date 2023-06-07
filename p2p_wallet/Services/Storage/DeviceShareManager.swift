//
//  DeviceShareManager.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/06/2023.
//

import Foundation
import Combine
import KeychainSwift
import Resolver

protocol DeviceShareManager {
    func save(deviceShare: String)
    var deviceShare: String? { get }
    var deviceSharePublisher: AnyPublisher<String?, Never> { get }
}

class DeviceShareManagerImpl: DeviceShareManager {
    
    let deviceShareKey = "deviceShareKey"
    let localKeychain: KeychainSwift
    let share = CurrentValueSubject<String?, Never>(nil)
    
    init() {
        let keyChainStorage = Resolver.resolve(KeychainStorage.self)
        localKeychain = keyChainStorage.localKeychain
        share.send(localKeychain.get(deviceShareKey))
    }
    
    func save(deviceShare: String) {
        if deviceShare.isEmpty {
            localKeychain.delete(deviceShareKey)
            share.send(nil)
        } else {
            localKeychain.set(deviceShare, forKey: deviceShareKey)
            share.send(deviceShare)
        }
    }
    
    var deviceShare: String? {
        share.value
    }
    
    var deviceSharePublisher: AnyPublisher<String?, Never> {
        share.eraseToAnyPublisher()
    }
    
    
}
