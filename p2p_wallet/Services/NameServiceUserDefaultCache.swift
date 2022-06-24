//
//  NameServiceUserDefaultCache.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2022.
//

import Foundation
import NameService
import Resolver

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
