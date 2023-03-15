//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import WalletCore
import Web3

/// Ethereum key pair.
/// This class stores secret data.
public struct EthereumKeyPair: Equatable, Hashable {
    public enum Error: Swift.Error {
        case invalidPhrase
    }

    /// Protected area data.
    internal let privateKey: EthereumPrivateKey

    /// Ethereum public key
    public var publicKey: String {
        privateKey.publicKey.hex()
    }

    /// Ethereum address (not eip55)
    public var address: String {
        privateKey.publicKey.address.hex(eip55: false)
    }

    /// Init with with raw
    public init(bytes: Bytes) throws {
        privateKey = try EthereumPrivateKey(privateKey: bytes)
    }

    /// Init key pair from phrase using m/44'/60'/0'/0/0 path
    public init(phrase: String) throws {
        guard let wallet = HDWallet(mnemonic: phrase, passphrase: "") else {
            throw Error.invalidPhrase
        }
        privateKey = try EthereumPrivateKey(privateKey: wallet.getKeyForCoin(coin: .ethereum).data.bytes)
    }
}
