//
//  WalletMetadataProvider.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 29.05.2023.
//

import Foundation
import Onboarding
import Resolver

enum WalletMetadataProviderError: Error {
    case invalidAction
    case unauthorised
    case deleteIsNotAllowed
}

protocol WalletMetadataProvider {
    func save(metadata: WalletMetaData?) async throws
    func load() async throws -> WalletMetaData?
}

class LocalWalletMetadataProvider: WalletMetadataProvider {
    @Injected private var keychainStorage: KeychainStorage

    private let key: String

    init() {
        if !Defaults.hasKey(\.keychainWalletMetadata) {
            Defaults.keychainWalletMetadata = UUID().uuidString
        }
        key = Defaults.keychainWalletMetadata!
    }

    func save(metadata: WalletMetaData?) async throws {
        if let metadata = metadata {
            let rawData = try JSONEncoder().encode(metadata)
            keychainStorage.localKeychain.set(rawData, forKey: key)
        } else {
            keychainStorage.localKeychain.delete(key)
        }
    }

    func load() async throws -> WalletMetaData? {
        guard let rawData: Data = keychainStorage.localKeychain.getData(key)
        else { return nil }

        return try JSONDecoder().decode(WalletMetaData.self, from: rawData)
    }
}

class RemoteWalletMetadataProvider: WalletMetadataProvider {
    @Injected private var apiGatewayClient: APIGatewayClient
    @Injected private var userWalletManager: UserWalletManager

    func save(metadata: WalletMetaData?) async throws {
        guard
            let wallet = userWalletManager.wallet,
            let ethAddress = wallet.ethAddress,
            let seedPhrase = wallet.seedPhrase
        else {
            throw WalletMetadataProviderError.unauthorised
        }

        guard let metadata else {
            throw WalletMetadataProviderError.deleteIsNotAllowed
        }

        let encryptedData = try metadata.encrypt(seedPhrase: seedPhrase.joined(separator: " "))

        try await apiGatewayClient.setMetadata(
            ethAddress: ethAddress,
            solanaPrivateKey: Base58.encode(wallet.account.secretKey),
            encryptedMetadata: encryptedData
        )
    }

    func load() async throws -> WalletMetaData? {
        guard
            let wallet = userWalletManager.wallet,
            let ethAddress = wallet.ethAddress,
            let seedPhrase = wallet.seedPhrase
        else { return nil }

        let encryptedMetadata = try await apiGatewayClient.getMetadata(
            ethAddress: ethAddress,
            solanaPrivateKey: Base58.encode(wallet.account.secretKey),
            timestampDevice: Date()
        )

        return try WalletMetaData.decrypt(
            ethAddress: ethAddress,
            seedPhrase: seedPhrase.joined(separator: " "),
            data: encryptedMetadata
        )
    }
}

class MockedWalletMeradataProvider: WalletMetadataProvider {
    private let value: WalletMetaData?

    init(_ value: WalletMetaData?) { self.value = value }

    func save(metadata _: WalletMetaData?) async throws {}

    func load() async throws -> WalletMetaData? { value }
}
