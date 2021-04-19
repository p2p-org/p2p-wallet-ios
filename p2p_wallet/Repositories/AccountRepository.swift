//
//  AccountRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation

protocol AccountRepository {
    func phrasesFromICloud() -> String?
    var phrases: [String]? {get}
    func save(_ pinCode: String)
}

extension KeychainAccountStorage: AccountRepository {}
