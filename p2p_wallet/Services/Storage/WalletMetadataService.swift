// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BankTransfer
import Combine
import Foundation
import KeyAppKitCore
import Onboarding
import Resolver

/// Service to manage user's metadata
actor WalletMetadataService {
    // MARK: - Dependencies

    @Injected var userWalletManager: UserWalletManager
    @Injected var errorObserver: ErrorObserver

    private let localMetadataProvider: WalletMetadataProvider
    private let remoteMetadataProvider: WalletMetadataProvider

    // MARK: - Subjects

    private let metadataSubject: CurrentValueSubject<AsyncValueState<WalletMetaData?>, Never> = .init(.init(value: nil))

    // MARK: - Private properties

    private var subscription: Set<AnyCancellable> = []

    // MARK: - Internal properties

    public nonisolated var metadata: AsyncValueState<WalletMetaData?> {
        metadataSubject.value
    }

    public nonisolated var metadataPublisher: AnyPublisher<AsyncValueState<WalletMetaData?>, Never> {
        metadataSubject.eraseToAnyPublisher()
    }

    /// Indicator for availability of metadata.
    nonisolated var isMetadataAvailable: Bool {
        metadataSubject.value.value != nil
    }

    // MARK: - Initializer

    init(localProvider: WalletMetadataProvider, remoteProvider: WalletMetadataProvider) {
        localMetadataProvider = localProvider
        remoteMetadataProvider = remoteProvider
    }

    // MARK: - Methods

    /// Synchornize data between local storage and remote storage.
    func synchronize() async {
        // Assert logged in user
        guard let userWallet = userWalletManager.wallet else {
            let error = WalletMetadataService.Error.unauthorized
            metadataSubject.value.error = error
            errorObserver.handleError(error)
            return
        }

        // Assert web3Auth user
        guard userWallet.ethAddress != nil else {
            metadataSubject.value.status = .ready
            metadataSubject.value.value = nil
            metadataSubject.value.error = WalletMetadataService.Error.notWeb3AuthUser
            return
        }

        // Mark as ready in the end
        defer {
            metadataSubject.value.status = .ready
        }

        do {
            // Warm up with local data
            metadataSubject.value.value = try await localMetadataProvider.load(for: userWallet)

            // Mark as fetching
            metadataSubject.value.status = .fetching
            metadataSubject.value.error = nil

            // Load from cloud, if no data just return
            guard let remoteMetadata = try await remoteMetadataProvider.load(for: userWallet)
            else {
                return
            }

            // If local metadata exists
            if let localMetadata = metadataSubject.value.value {
                // Assert localMetadata != remoteMetadata, otherwise just return
                guard localMetadata != remoteMetadata else {
                    return
                }

                // Local metadata and remote metadata are not equal
                // Try merge data
                let mergedMetadata = try WalletMetaData.merge(lhs: localMetadata, rhs: remoteMetadata)

                // Assign metadata
                metadataSubject.value.value = mergedMetadata

                // Push update to localMetadata
                try await localMetadataProvider.save(for: userWallet, metadata: mergedMetadata)

                // Push updated data to remote storage
                do {
                    try await remoteMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
                } catch {
                    throw WalletMetadataService.Error.remoteSynchronizationFailure
                }

            } else {
                // Local metadata doesn't exists
                metadataSubject.value.value = remoteMetadata

                // Push update to localMetadata
                try await localMetadataProvider.save(for: userWallet, metadata: remoteMetadata)
            }
        } catch {
            metadataSubject.value.error = error
            errorObserver.handleError(error)
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

        await synchronize()
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

extension WalletMetadataService: StrigaMetadataProvider {
    func getStrigaMetadata() async -> StrigaMetadata? {
        guard let metadata = metadata.value else {
            return nil
        }
        return .init(
            userId: metadata.striga.userId,
            email: metadata.email,
            phoneNumber: metadata.phoneNumber
        )
    }
    
    func updateMetadata(withUserId userId: String) async throws {
        guard var newData = metadata.value else {
            return
        }
        newData.striga.userId = userId
        
        try await update(newData)
    }
}
