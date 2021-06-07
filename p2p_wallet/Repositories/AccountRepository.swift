//
//  AccountRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation
import RxSwift

protocol AccountRepository {
    func phrasesFromICloud() -> String?
    func getCurrentPhrases() -> Single<[String]?>
    func save(_ pinCode: String)
}

extension KeychainAccountStorage: AccountRepository {
    func getCurrentPhrases() -> Single<[String]?> {
        getCurrentAccount().map {$0?.phrase}
    }
}
