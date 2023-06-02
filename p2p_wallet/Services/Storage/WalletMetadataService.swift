// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import KeyAppKitCore
import Onboarding
import Resolver

class WalletMetadataService {
    @Injected var userWalletManager: UserWalletManager

    private let metadataValue: CurrentAsyncValue<WalletMetaData?> = .init(state: .init(value: nil))

    var metadata: AsyncValueState<WalletMetaData?> {
        metadataValue.state
    }

    var metadataPublisher: AnyPublisher<AsyncValueState<WalletMetaData?>, Never> {
        metadataValue.publisher
    }

    private let localMetadataProvider: WalletMetadataProvider
    private let remoteMetadataProvider: WalletMetadataProvider

    var subscription: [AnyCancellable] = []

    init(localProvider: WalletMetadataProvider, remoteProvider: WalletMetadataProvider) {
        localMetadataProvider = localProvider
        remoteMetadataProvider = remoteProvider
    }

    func synchronize() async throws {
        guard let userWallet = userWalletManager.wallet else {
            throw WalletMetadataService.Error.unauthorized
        }

        // Warm up with local data
        metadataValue.state.value = try await localMetadataProvider.load(for: userWallet)

        do {
            metadataValue.state.status = .fetching
            metadataValue.state.error = nil

            defer {
                metadataValue.state.status = .ready
            }

            // Load from cloud
            let remoteMetadata = try await remoteMetadataProvider.load(for: userWallet)

            if
                let localMetadata = metadataValue.state.value,
                let remoteMetadata,
                localMetadata != remoteMetadata
            {
                let mergedMetadata = try WalletMetaData.merge(lhs: localMetadata, rhs: remoteMetadata)

                try await localMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
                try await remoteMetadataProvider.save(for: userWallet, metadata: mergedMetadata)

                metadataValue.state.value = mergedMetadata
            } else {
                metadataValue.state.value = remoteMetadata
                try await localMetadataProvider.save(for: userWallet, metadata: remoteMetadata)
            }
        } catch {
            metadataValue.state.error = error
            throw error
        }
    }

    func update(_ newMetadata: WalletMetaData) async throws {
        try await synchronize()

        guard let userWallet = userWalletManager.wallet else {
            throw WalletMetadataService.Error.unauthorized
        }

        guard let localMetadata = metadataValue.state.value else {
            throw WalletMetadataService.Error.missingLocalMetadata
        }

        let mergedMetadata = try WalletMetaData.merge(lhs: localMetadata, rhs: newMetadata)
        try await localMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
        try await remoteMetadataProvider.save(for: userWallet, metadata: mergedMetadata)

        metadataValue.state.value = newMetadata
    }

    func clear() async throws {
        metadataValue.state.value = nil
    }
}

extension WalletMetadataService {
    enum Error: Swift.Error {
        case unauthorized
        case missingLocalMetadata
    }
}
