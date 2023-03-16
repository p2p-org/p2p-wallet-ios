//
//  File.swift
//
//
//  Created by Giang Long Tran on 15.03.2023.
//

import Foundation
import Web3

public extension EthereumKeyPair {
    func sign(transaction: EthereumTransaction, chainID: EthereumQuantity) throws -> EthereumSignedTransaction {
        return try transaction.sign(with: privateKey, chainId: chainID)
    }
}
