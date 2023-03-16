//
//  EthereumTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.03.2023.
//

import Collections
import Foundation
import Web3

public extension EthereumTransaction {
    init(rlp: RLPItem) throws {
        guard let array = rlp.array else {
            throw EthereumSignedTransaction.Error.rlpItemInvalid
        }

        if array.count == 9 {
            guard
                let nonce = array[0].bigUInt,
                let gasPrice = array[1].bigUInt,
                let gasLimit = array[2].bigUInt,
                let toBytes = array[3].bytes,
                let value = array[4].bigUInt,
                let data = array[5].bytes,
                let chainID = array[6].uint
            else {
                throw EthereumSignedTransaction.Error.rlpItemInvalid
            }
            
            print(chainID)

            try self.init(
                nonce: EthereumQuantity(quantity: nonce),
                gasPrice: EthereumQuantity(quantity: gasPrice),
                gasLimit: EthereumQuantity(quantity: gasLimit),
                to: EthereumAddress(rawAddress: toBytes),
                value: EthereumQuantity(quantity: value),
                data: EthereumData(data)
            )

            return
        }

        throw EthereumSignedTransaction.Error.rlpItemInvalid
    }
}
