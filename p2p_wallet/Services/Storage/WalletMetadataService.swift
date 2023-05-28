// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Onboarding
import Resolver

class WalletMetadataService: ObservableObject {
    @Published var loading: Bool = false
    @Published var metadata: WalletMetaData?

    private let localMetadataProvider: WalletMetadataProvider
    private let remoteMetadataProvider: WalletMetadataProvider

    init(localProvider: WalletMetadataProvider, remoteProvider: WalletMetadataProvider) {
        localMetadataProvider = localProvider
        remoteMetadataProvider = remoteProvider
    }

    func synchronize(initialMetadata: WalletMetaData? = nil) async throws {
        if let initialMetadata = initialMetadata {
            try await localMetadataProvider.save(metadata: initialMetadata)
            metadata = initialMetadata
        } else {
            metadata = try await localMetadataProvider.load()
            do {
                loading = true
                defer { loading = false }

                let remoteMetadata = try await remoteMetadataProvider.load()

                if
                    let metadata,
                    let remoteMetadata,
                    metadata != remoteMetadata
                {
                    let mergedMetadata = WalletMetaData.merge(lhs: metadata, rhs: remoteMetadata)

                    try await localMetadataProvider.save(metadata: mergedMetadata)
                    try await remoteMetadataProvider.save(metadata: mergedMetadata)

                    metadata = mergedMetadata
                } else {
                    try await localMetadataProvider.save(metadata: remoteMetadata)
                    metadata = remoteMetadata
                }
            } catch {
                print(error)
                throw error
            }
        }
    }

    func update(_ newMetadata: WalletMetaData) async throws {
        guard let metadata else {
            throw WalletMetadataService.Error.missingLocalMetadata
        }

        let mergedMetadata = WalletMetaData.merge(lhs: metadata, rhs: newMetadata)
        try await localMetadataProvider.save(metadata: mergedMetadata)
        try await remoteMetadataProvider.save(metadata: mergedMetadata)
    }

    func clear() async throws {
        try await localMetadataProvider.save(metadata: nil)
    }
}

extension WalletMetadataService {
    enum Error: Swift.Error {
        case missingLocalMetadata
    }
}
