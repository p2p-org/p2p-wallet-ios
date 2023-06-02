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

    private let metadataSubject: CurrentValueSubject<AsyncValueState<WalletMetaData?>, Never> = .init(.init(value: nil))

    public var metadata: AsyncValueState<WalletMetaData?> {
        metadataSubject.value
    }

    public var metadataPublisher: AnyPublisher<AsyncValueState<WalletMetaData?>, Never> {
        metadataSubject.eraseToAnyPublisher()
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

        if userWallet.ethAddress == nil {
            metadataSubject.value.status = .ready
            metadataSubject.value.value = nil
        } else {
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
    }

    func update(_ newMetadata: WalletMetaData) async throws {
        guard let userWallet = userWalletManager.wallet else {
            throw WalletMetadataService.Error.unauthorized
        }

        if userWallet.ethAddress == nil {
            return
        } else {
            try await synchronize()

            guard let localMetadata = metadataSubject.value.value else {
                throw WalletMetadataService.Error.missingLocalMetadata
            }

            let mergedMetadata = try WalletMetaData.merge(lhs: localMetadata, rhs: newMetadata)

            // Push updated data to local storage
            try await localMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
            metadataSubject.value.value = newMetadata

            // Push updated data to local storage
            do {
                try await remoteMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
            } catch {
                throw WalletMetadataService.Error.remoteSynchronizationFailure
            }
        }
    }
}

extension WalletMetadataService {
    enum Error: Swift.Error {
        case unauthorized
        case missingLocalMetadata
        case remoteSynchronizationFailure
    }
}
