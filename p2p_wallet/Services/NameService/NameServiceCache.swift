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
        case let .registered(string):
            return string
        }
    }
}

class NameServiceUserDefaultCache: NameServiceCacheType {
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var nameStorage: NameStorageType

    private let locker = NSLock()
    private var addressToNameCache = [String: NameServiceSearchResult]() // Address: Name

    func save(_ name: String?, for owner: String) {
        locker.lock(); defer { locker.unlock() }
        guard let name = name else {
            addressToNameCache[owner] = .notRegisteredYet
            return
        }
        addressToNameCache[owner] = .registered(name)
    }

    func getName(for owner: String) -> NameServiceSearchResult? {
        if walletsRepository.getWallets().contains(where: { $0.pubkey == owner }),
           let name = nameStorage.getName()
        {
            return .registered(name)
        }
        return addressToNameCache[owner]
    }
}
