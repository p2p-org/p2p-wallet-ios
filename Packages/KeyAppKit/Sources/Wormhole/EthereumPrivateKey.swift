//
//  File.swift
//  
//
//  Created by Giang Long Tran on 01.03.2023.
//

import Foundation
import Web3
import SolanaSwift
import WalletCore

public extension EthereumPrivateKey {
    convenience init(phrase: String, derivationPath: String = "m/44'/60'/0'/0/0") throws {
        let wallet = HDWallet(mnemonic: phrase, passphrase: "")!
        
        try self.init(privateKey: wallet.getKeyForCoin(coin: .ethereum).data.bytes)
    }
}
