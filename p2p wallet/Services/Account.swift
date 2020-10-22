//
//  Account.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import Foundation
import TweetNacl
import CryptoSwift

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
        
        let seed = mnemonic.seed
        let keys = try NaclSign.KeyPair.keyPair(fromSecretKey: Data(seed))
        
        self.publicKey = keys.publicKey.base64EncodedString()
        self.secretKey = keys.secretKey.base64EncodedString()
    }
}
