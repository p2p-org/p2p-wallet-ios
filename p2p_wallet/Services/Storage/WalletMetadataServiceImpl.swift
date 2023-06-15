// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import KeyAppKitCore
import Onboarding
import Resolver

actor WalletMetadataServiceImpl: WalletMetadataService {
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
    private let remoteMetadataProvider: [WalletMetadataProvider]

    var subscription: [AnyCancellable] = []

    init(localProvider: WalletMetadataProvider, remoteProvider: [WalletMetadataProvider]) {
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
            let error = WalletMetadataServiceImpl.Error.unauthorized
            errorObserver.handleError(error)
            throw error
        }

        guard userWallet.ethAddress != nil else {
            metadataSubject.value.status = .ready
            metadataSubject.value.value = nil

            throw WalletMetadataServiceImpl.Error.notWeb3AuthUser
        }

        // Warm up with local data
        metadataSubject.value.value = try await localMetadataProvider.load(for: userWallet)

        do {
            metadataSubject.value.status = .fetching
            metadataSubject.value.error = nil

            await acquireWrite()

            defer {
                metadataSubject.value.status = .ready
            }

            // Load from cloud
            let (remoteMetadata, remoteSync) = try await fetchRemote(userWallet: userWallet)

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
                    try await write(userWallet: userWallet, metadata: mergedMetadata)
                } catch {
                    errorObserver.handleError(error)
                    throw WalletMetadataServiceImpl.Error.remoteSynchronizationFailure
                }
            } else {
                if let remoteMetadata {
                    // Push updated data to local storage
                    metadataSubject.value.value = remoteMetadata
                    try await localMetadataProvider.save(for: userWallet, metadata: remoteMetadata)

                    // Push updated data to remote storages in case they are not synchronised.
                    if remoteSync == false {
                        try await write(userWallet: userWallet, metadata: remoteMetadata)
                    }
                }
            }

            await releaseWrite()
        } catch {
            await releaseWrite()
            metadataSubject.value.error = error
            throw error
        }
    }

    /// Update metadata
    func update(_ newMetadata: WalletMetaData) async throws {
        guard let userWallet = userWalletManager.wallet else {
            throw WalletMetadataServiceImpl.Error.unauthorized
        }

        guard userWallet.ethAddress != nil else {
            throw WalletMetadataServiceImpl.Error.notWeb3AuthUser
        }

        // Push updated data to local storage
        try await localMetadataProvider.save(for: userWallet, metadata: newMetadata)
        metadataSubject.value.value = newMetadata

        try await synchronize()
    }

    private func acquireWrite() async {
        for provider in remoteMetadataProvider {
            await provider.acquireWrite()
        }
    }

    private func releaseWrite() async {
        for provider in remoteMetadataProvider {
            await provider.releaseWrite()
        }
    }

    private func write(userWallet: UserWallet, metadata: WalletMetaData) async throws {
        for provider in remoteMetadataProvider {
            try await provider.save(for: userWallet, metadata: metadata)
        }
    }

    private func fetchRemote(userWallet: UserWallet) async throws
    -> (metadata: WalletMetaData?, sync: Bool) {
        var multipleRemoteMetadata: [WalletMetaData?] = try await withThrowingTaskGroup(
            of: WalletMetaData?.self
        ) { group in
            for remoteProvider in remoteMetadataProvider {
                // Check provider is ready
                guard await remoteProvider.ready else { continue }

                group.addTask {
                    let metadata = try await remoteProvider.load(for: userWallet)

                    if let metadata {
                        return metadata
                    } else {
                        return nil
                    }
                }
            }

            var metadatas: [WalletMetaData?] = []
            for try await result in group {
                metadatas.append(result)
            }

            return metadatas
        }

        let filteredMultipleRemoteMetadata = multipleRemoteMetadata.compactMap { $0 }
        var sync: Bool
        let remoteMetadata: WalletMetaData?

        // Merge multi remote metadata into one
        switch filteredMultipleRemoteMetadata.count {
        case 0:
            sync = false
            remoteMetadata = nil
        case 1:
            sync = true
            remoteMetadata = filteredMultipleRemoteMetadata.first!
        case 2:
            sync = filteredMultipleRemoteMetadata.first! == filteredMultipleRemoteMetadata.last!
            remoteMetadata = try WalletMetaData.merge(
                lhs: filteredMultipleRemoteMetadata.first!,
                rhs: filteredMultipleRemoteMetadata.last!
            )
        default:
            sync = filteredMultipleRemoteMetadata.allSatisfy {
                filteredMultipleRemoteMetadata.first! == $0
            }

            remoteMetadata = try filteredMultipleRemoteMetadata
                .reduce(filteredMultipleRemoteMetadata.first!) { partialResult, next in
                    try WalletMetaData.merge(lhs: partialResult, rhs: next)
                }
        }

        if filteredMultipleRemoteMetadata.count != multipleRemoteMetadata.count {
            sync = false
        }

        return (remoteMetadata, sync)
    }
}

extension WalletMetadataServiceImpl {
    enum Error: Swift.Error {
        case unauthorized

        case notWeb3AuthUser

        case missingLocalMetadata

        case missingRemoteMetadata

        case remoteSynchronizationFailure
    }
}
