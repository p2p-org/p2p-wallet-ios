//
//  Account.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import Foundation
import TweetNacl
import Base58Swift

class Account {
    let phrase: [String]
    let publicKey: String
    let secretKey: String
    
    init(phrase: [String] = []) throws {
        let mnemonic: Mnemonic
        if !phrase.isEmpty {
            mnemonic = try Mnemonic(phrase: phrase)
        } else {
            mnemonic = Mnemonic()
        }
        self.phrase = mnemonic.phrase
        
        let seed = mnemonic.seed[0..<32]
        let keys = try NaclSign.KeyPair.keyPair(fromSeed: Data(seed))
        
        self.publicKey = Base58.base58Encode([UInt8](keys.publicKey))
        self.secretKey = Base58.base58Encode([UInt8](keys.secretKey))
    }
}
