// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import KeyAppKitCore
import Onboarding
import Resolver

actor WalletMetadataService {
    @Injected var userWalletManager: UserWalletManager
    @Injected var errorObserver: ErrorObserver

    private let metadataSubject: CurrentValueSubject<AsyncValueState<WalletMetaData?>, Never> = .init(.init(value: nil))

    public nonisolated var metadata: AsyncValueState<WalletMetaData?> {
        metadataSubject.value
    }

    public nonisolated var metadataPublisher: AnyPublisher<AsyncValueState<WalletMetaData?>, Never> {
        metadataSubject.eraseToAnyPublisher()
    }

    private let localMetadataProvider: WalletMetadataProvider
    private let remoteMetadataProvider: WalletMetadataProvider

    var subscription: [AnyCancellable] = []

    init(localProvider: WalletMetadataProvider, remoteProvider: WalletMetadataProvider) {
        localMetadataProvider = localProvider
        remoteMetadataProvider = remoteProvider
    }

    /// Indicator for availability of metadata.
    nonisolated var isMetadataAvailable: Bool {
        metadataSubject.value.value != nil
    }

    /// Synchornize data between local storage and remote storage.
    func synchronize() async throws {
        guard let userWallet = userWalletManager.wallet else {
            let error = WalletMetadataService.Error.unauthorized
            errorObserver.handleError(error)
            throw error
        }

        guard userWallet.ethAddress != nil else {
            metadataSubject.value.status = .ready
            metadataSubject.value.value = nil

            throw WalletMetadataService.Error.notWeb3AuthUser
        }

        // Warm up with local data
        metadataSubject.value.value = try await localMetadataProvider.load(for: userWallet)

        do {
            metadataSubject.value.status = .fetching
            metadataSubject.value.error = nil

            defer {
                metadataSubject.value.status = .ready
            }

            // Load from cloud
            let remoteMetadata = try await remoteMetadataProvider.load(for: userWallet)

            if
                let localMetadata = metadataSubject.value.value,
                let remoteMetadata,
                localMetadata != remoteMetadata
            {
                // Try merge data if they are difference
                let mergedMetadata = try WalletMetaData.merge(lhs: localMetadata, rhs: remoteMetadata)

                // Push updated data to local storage
                try await localMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
                metadataSubject.value.value = mergedMetadata

                // Push updated data to remote storage
                do {
                    try await remoteMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
                } catch {
                    errorObserver.handleError(error)
                    throw WalletMetadataService.Error.remoteSynchronizationFailure
                }
            } else {
                // Push updated data to local storage
                metadataSubject.value.value = remoteMetadata
                try await localMetadataProvider.save(for: userWallet, metadata: remoteMetadata)
            }
        } catch {
            metadataSubject.value.error = error
            throw error
        }
    }

    /// Update metadata
    func update(_ newMetadata: WalletMetaData) async throws {
        guard let userWallet = userWalletManager.wallet else {
            throw WalletMetadataService.Error.unauthorized
        }

        guard userWallet.ethAddress != nil else {
            throw WalletMetadataService.Error.notWeb3AuthUser
        }

        // Push updated data to local storage
        try await localMetadataProvider.save(for: userWallet, metadata: newMetadata)
        metadataSubject.value.value = newMetadata

        try await synchronize()
    }
}

extension WalletMetadataService {
    enum Error: Swift.Error {
        case unauthorized

        case notWeb3AuthUser

        case missingLocalMetadata

        case remoteSynchronizationFailure
    }
}
