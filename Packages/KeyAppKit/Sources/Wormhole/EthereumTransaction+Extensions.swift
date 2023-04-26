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
        // Used for EIP1559
        if array.count == 9 {
            guard
                let nonce = array[EthereumTransaction.RLPKey.nonce.rawValue].bigUInt,
                let maxPriorityFeePerGas = array[EthereumTransaction.RLPKey.maxPriorityFeePerGas.rawValue].bigUInt,
                let maxFeePerGas = array[EthereumTransaction.RLPKey.maxFeePerGas.rawValue].bigUInt,
                let gasLimit = array[EthereumTransaction.RLPKey.gasLimit.rawValue].bigUInt,
                let to = array[EthereumTransaction.RLPKey.to.rawValue].bytes,
                let amount = array[EthereumTransaction.RLPKey.amount.rawValue].bigUInt,
                let data = array[EthereumTransaction.RLPKey.data.rawValue].bytes
            else {
                throw EthereumSignedTransaction.Error.rlpItemInvalid
            }

            try self.init(
                nonce: EthereumQuantity(quantity: nonce),
                maxFeePerGas: EthereumQuantity(quantity: maxFeePerGas),
                maxPriorityFeePerGas: EthereumQuantity(quantity: maxPriorityFeePerGas),
                gasLimit: EthereumQuantity(quantity: gasLimit),
                to: EthereumAddress(rawAddress: to),
                value: EthereumQuantity(quantity: amount),
                data: EthereumData(data),
                accessList: Self.accesslist(item: array[EthereumTransaction.RLPKey.accessList.rawValue]),
                transactionType: .eip1559
            )
            return
        } else if array.count > 7 {
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

    static func accesslist(item: RLPItem) -> OrderedDictionary<EthereumAddress, [EthereumData]> {
        var newAccessList = OrderedDictionary<EthereumAddress, [EthereumData]>()
        (item.array ?? []).forEach { item in
            let element = item.array
            guard
                let bytes = element?[0].bytes,
                let ethDataArray = element?[1].array,
                let addr = try? EthereumAddress(rawAddress: bytes) else { return }
                newAccessList[addr] = ethDataArray.compactMap { item in
                    guard let bytes = item.bytes else { return nil }
                    return EthereumData(bytes)
                }
        }
        return newAccessList
    }

}

extension EthereumTransaction {
    private enum RLPKey: Int, CaseIterable {
        case chainId
        case nonce
        case maxPriorityFeePerGas
        case maxFeePerGas
        case gasLimit
        case to
        case amount
        case data
        case accessList
        case v
        case r
        case s
    }
}
