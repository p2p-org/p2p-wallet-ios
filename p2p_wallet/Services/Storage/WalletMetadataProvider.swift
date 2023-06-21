//
//  WalletMetadataProvider.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 29.05.2023.
//

import Foundation
import KeyAppKitCore
import KeychainSwift
import Onboarding
import Resolver

actor LocalWalletMetadataProvider: WalletMetadataProvider {
    /// Local device keychain
    let keychain: KeychainSwift

    init() {
        let keychainStorage: KeychainStorage = Resolver.resolve()

        keychain = keychainStorage.metadataKeychain

        Task {
            // Migrate to long-term data saving. We delete them.
            if let oldKey = Defaults.keychainWalletMetadata {
                keychainStorage.localKeychain.delete(oldKey)
            }
        }
    }

    nonisolated var ready: Bool { true }

    func acquireWrite() async {}

    func releaseWrite() async {}

    func save(for userWallet: UserWallet, metadata: WalletMetaData?) async throws {
        guard userWallet.ethAddress == metadata?.ethPublic else {
            throw WalletMetadataProviderError.unauthorised
        }

        if
            let metadata = metadata,
            let seedPhrase = userWallet.seedPhrase
        {
            let encryptedMetadata = try metadata.encrypt(seedPhrase: seedPhrase.joined(separator: " "))
            keychain.set(encryptedMetadata, forKey: metadata.ethPublic)
        }
    }

    func load(for userWallet: UserWallet) async throws -> WalletMetaData? {
        guard
            let ethAddress = userWallet.ethAddress,
            let seedPhrase = userWallet.seedPhrase,
            let encryptedMetadata = keychain.get(ethAddress)
        else { return nil }

        return try WalletMetaData.decrypt(
            ethAddress: ethAddress,
            seedPhrase: seedPhrase.joined(separator: " "),
            data: encryptedMetadata
        )
    }
}

actor RemoteWalletMetadataProvider: WalletMetadataProvider {
    @Injected private var apiGatewayClient: APIGatewayClient

    nonisolated var ready: Bool { true }

    func acquireWrite() async {}

    func releaseWrite() async {}

    func save(for userWallet: UserWallet, metadata: WalletMetaData?) async throws {
        guard
            let ethAddress = userWallet.ethAddress,
            userWallet.ethAddress == metadata?.ethPublic,
            let seedPhrase = userWallet.seedPhrase
        else {
            throw WalletMetadataProviderError.unauthorised
        }

        guard let metadata else {
            throw WalletMetadataProviderError.deleteIsNotAllowed
        }

        let encryptedData = try metadata.encrypt(seedPhrase: seedPhrase.joined(separator: " "))

        try await apiGatewayClient.setMetadata(
            ethAddress: ethAddress,
            solanaPrivateKey: Base58.encode(userWallet.account.secretKey),
            encryptedMetadata: encryptedData
        )
    }

    func load(for userWallet: UserWallet) async throws -> WalletMetaData? {
        guard
            let ethAddress = userWallet.ethAddress,
            let seedPhrase = userWallet.seedPhrase
        else { return nil }

        let encryptedMetadata = try await apiGatewayClient.getMetadata(
            ethAddress: ethAddress,
            solanaPrivateKey: Base58.encode(userWallet.account.secretKey),
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

    let ready: Bool = true

    init(_ value: WalletMetaData?) { self.value = value }

    func acquireWrite() async {}

    func releaseWrite() async {}

    func save(for _: UserWallet, metadata _: WalletMetaData?) async throws {}

    func load(for _: UserWallet) async throws -> WalletMetaData? { value }
}
