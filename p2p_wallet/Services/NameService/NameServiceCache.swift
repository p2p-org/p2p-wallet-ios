//
//  NameServiceCache.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/03/2022.
//

import Foundation

protocol NameServiceCacheType {
    func save(_ name: String?, for owner: String)
    func getName(for owner: String) -> NameServiceSearchResult?
}

enum NameServiceSearchResult {
    case notRegisteredYet
    case registered(String)
    
    var name: String? {
        switch self {
        case .notRegisteredYet:
            return nil
        case .registered(let string):
            return string
        }
    }
}

class NameServiceUserDefaultCache: NameServiceCacheType {
    private var addressToNameCache = [String: NameServiceSearchResult]() // Address: Name
    private let locker = NSLock()
    
    func save(_ name: String?, for owner: String) {
        guard let name = name else {
            addressToNameCache[owner] = .notRegisteredYet
            return
        }
        addressToNameCache[owner] = .registered(name)
    }
    
    func getName(for owner: String) -> NameServiceSearchResult? {
        addressToNameCache[owner]
    }
}
