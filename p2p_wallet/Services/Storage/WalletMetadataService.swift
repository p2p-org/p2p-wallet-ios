// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver

class WalletMetadataService: ObservableObject {
    @Injected var userWalletManager: UserWalletManager

    @Published var loading: Bool = false
    @Published var metadata: WalletMetaData?

    private let localMetadataProvider: WalletMetadataProvider
    private let remoteMetadataProvider: WalletMetadataProvider

    var subscription: [AnyCancellable] = []

    init(localProvider: WalletMetadataProvider, remoteProvider: WalletMetadataProvider) {
        localMetadataProvider = localProvider
        remoteMetadataProvider = remoteProvider

        userWalletManager.$wallet.sink { [weak self] wallet in
            if wallet == nil {
                self?.metadata = nil
            }
        }
        .store(in: &subscription)
    }

    func synchronize() async throws {
        guard let userWallet = userWalletManager.wallet else {
            throw WalletMetadataService.Error.unauthorized
        }

        // Warm up with local data
        metadata = try await localMetadataProvider.load(for: userWallet)

        do {
            loading = true
            defer { loading = false }

            // Load from cloud
            let remoteMetadata = try await remoteMetadataProvider.load(for: userWallet)

            if
                let metadata,
                let remoteMetadata,
                metadata != remoteMetadata
            {
                let mergedMetadata = try WalletMetaData.merge(lhs: metadata, rhs: remoteMetadata)

                try await localMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
                try await remoteMetadataProvider.save(for: userWallet, metadata: mergedMetadata)

                self.metadata = mergedMetadata
            } else {
                try await localMetadataProvider.save(for: userWallet, metadata: remoteMetadata)
                metadata = remoteMetadata
            }
        } catch {
            print(error)
            throw error
        }
    }

    func update(_ newMetadata: WalletMetaData) async throws {
        guard let userWallet = userWalletManager.wallet else {
            throw WalletMetadataService.Error.unauthorized
        }

        guard let metadata else {
            throw WalletMetadataService.Error.missingLocalMetadata
        }

        let mergedMetadata = try WalletMetaData.merge(lhs: metadata, rhs: newMetadata)
        try await localMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
        try await remoteMetadataProvider.save(for: userWallet, metadata: mergedMetadata)

        self.metadata = newMetadata
    }

    func clear() async throws {
        metadata = nil
    }
}

extension WalletMetadataService {
    enum Error: Swift.Error {
        case unauthorized
        case missingLocalMetadata
    }
}
