//
//  InMemoryAccountStorage.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 10/28/20.
//

import Foundation
import SolanaSwift

class InMemoryAccountStorage: SolanaSDKAccountStorage {
    private var _account: SolanaSDK.Account?
    func save(_ account: SolanaSDK.Account) throws {
        _account = account
    }
    var account: SolanaSDK.Account? {
        _account
    }
}
