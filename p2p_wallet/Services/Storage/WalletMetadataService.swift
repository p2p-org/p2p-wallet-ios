// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Onboarding
import Resolver

enum WalletMetadataProviderError: Error {
    case invalidAction
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

    func save(metadata _: WalletMetaData?) async throws {
        throw WalletMetadataProviderError.invalidAction
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

        return try WalletMetaData.decrypt(seedPhrase: seedPhrase.joined(separator: " "), data: encryptedMetadata)
    }
}

class MockedWalletMeradataProvider: WalletMetadataProvider {
    private let value: WalletMetaData?
    
    init(_ value: WalletMetaData?) { self.value = value }
    
    func save(metadata _: WalletMetaData?) async throws {}

    func load() async throws -> WalletMetaData? { value }
}

class WalletMetadataService: ObservableObject {
    @Published var loading: Bool = false
    @Published var metadata: WalletMetaData?

    private let localMetadataProvider: WalletMetadataProvider
    private let remoteMetadataProvider: WalletMetadataProvider

    init(localProvider: WalletMetadataProvider, remoteProvider: WalletMetadataProvider) {
        localMetadataProvider = localProvider
        remoteMetadataProvider = remoteProvider
    }

    func update(initialMetadata: WalletMetaData? = nil) async throws {
        if let initialMetadata = initialMetadata {
            try await localMetadataProvider.save(metadata: initialMetadata)
            metadata = initialMetadata
        } else {
            metadata = try await localMetadataProvider.load()
            do {
                loading = true
                defer { loading = false }
                let remoteMetadata = try await remoteMetadataProvider.load()
                try await localMetadataProvider.save(metadata: remoteMetadata)
                metadata = remoteMetadata
            } catch {
                print(error)
                throw error
            }
        }
    }

    func clear() async throws {
        try await localMetadataProvider.save(metadata: nil)
    }
}
