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

        if array.count == 7 {
            guard
                let nonce = array[0].bigUInt,
                let gasPrice = array[1].bigUInt,
                let gasLimit = array[2].bigUInt,
                let fromBytes = array[3].bytes,
                let toBytes = array[4].bytes,
                let from = try? EthereumAddress(rawAddress: fromBytes),
                let to = try? EthereumAddress(rawAddress: toBytes),
                let value = array[5].bigUInt,
                let data = array[6].bytes
            else {
                throw EthereumSignedTransaction.Error.rlpItemInvalid
            }

            self.init(
                nonce: EthereumQuantity(quantity: nonce),
                gasPrice: EthereumQuantity(quantity: gasPrice),
                gasLimit: EthereumQuantity(quantity: gasLimit),
                from: from,
                to: to,
                value: EthereumQuantity(quantity: value),
                data: EthereumData(data)
            )
        }

        throw EthereumSignedTransaction.Error.rlpItemInvalid
    }
}
