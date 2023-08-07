import Combine
import Foundation
import KeyAppKitCore

public actor WalletMetadataServiceImpl: WalletMetadataService {
    let errorObserver: ErrorObserver
    let realtimeErrorConfig: ErrorObserverConfig = .init(domain: "Metadata service", flags: .realtimeAlert)

    let currentUserWallet: CurrentUserWallet
    let localMetadataProvider: WalletMetadataProvider
    let remoteMetadataProvider: [WalletMetadataProvider]

    private let metadataSubject: CurrentValueSubject<AsyncValueState<WalletMetaData?>, Never> = .init(.init(value: nil))

    var subscription: [AnyCancellable] = []

    public init(
        currentUserWallet: CurrentUserWallet,
        errorObserver: ErrorObserver,
        localMetadataProvider: WalletMetadataProvider,
        remoteMetadataProvider: [WalletMetadataProvider]
    ) {
        self.currentUserWallet = currentUserWallet
        self.errorObserver = errorObserver
        self.localMetadataProvider = localMetadataProvider
        self.remoteMetadataProvider = remoteMetadataProvider
    }

    /// Indicator for availability of metadata.
    nonisolated var isMetadataAvailable: Bool {
        metadataSubject.value.value != nil
    }

    /// Synchornize data between local storage and remote storage.
    public func synchronize() async {
        guard let userWallet = currentUserWallet.value else {
            errorObserver.handleError(Error.unauthorized)
            return
        }

        guard userWallet.ethAddress != nil else {
            metadataSubject.value.status = .ready
            metadataSubject.value.value = nil

            errorObserver.handleError(Error.notWeb3AuthUser)
            return
        }

        do {
            // Warm up with local data
            metadataSubject.value.value = try await localMetadataProvider.load(for: userWallet)

            // Start fetching
            metadataSubject.value.status = .fetching
            metadataSubject.value.error = nil

            // Acquire write access
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

                print(localMetadata)
                print(remoteMetadata)

                // Push updated data to local storage
                try await localMetadataProvider.save(for: userWallet, metadata: mergedMetadata)
                metadataSubject.value.value = mergedMetadata

                // Push updated data to remote storage
                await write(userWallet: userWallet, metadata: mergedMetadata)
            } else {
                if let remoteMetadata {
                    // Push updated data to local storage
                    metadataSubject.value.value = remoteMetadata
                    try await localMetadataProvider.save(for: userWallet, metadata: remoteMetadata)

                    // Push updated data to remote storages in case they are not synchronised.
                    if remoteSync == false {
                        await write(userWallet: userWallet, metadata: remoteMetadata)
                    }
                }
            }

            await releaseWrite()
        } catch {
            await releaseWrite()
            metadataSubject.value.error = error
            errorObserver.handleError(error, config: realtimeErrorConfig)
        }
    }

    /// Update metadata
    public func update(_ newMetadata: WalletMetaData) async {
        guard let userWallet = currentUserWallet.value else {
            errorObserver.handleError(Error.unauthorized, config: realtimeErrorConfig)
            return
        }

        guard userWallet.ethAddress != nil else {
            errorObserver.handleError(Error.notWeb3AuthUser, config: realtimeErrorConfig)
            return
        }

        do {
            // Push updated data to local storage
            try await localMetadataProvider.save(for: userWallet, metadata: newMetadata)
            metadataSubject.value.value = newMetadata
        } catch {
            errorObserver.handleError(error, config: realtimeErrorConfig)
        }

        await synchronize()
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

    private func write(userWallet: UserWallet, metadata: WalletMetaData) async {
        for provider in remoteMetadataProvider {
            do {
                try await provider.save(for: userWallet, metadata: metadata)
            } catch {
                errorObserver.handleError(error, config: realtimeErrorConfig)
            }
        }
    }

    private func fetchRemote(userWallet: UserWallet) async throws
    -> (metadata: WalletMetaData?, sync: Bool) {
        let multipleRemoteMetadata: [WalletMetaData?] = await withTaskGroup(of: WalletMetaData?.self) { [self] group in
            for remoteProvider in self.remoteMetadataProvider {
                // Check provider is ready
                guard await remoteProvider.ready else { continue }

                group.addTask {
                    do {
                        let metadata = try await remoteProvider.load(for: userWallet)

                        if let metadata {
                            return metadata
                        } else {
                            return nil
                        }
                    } catch {
                        self.errorObserver.handleError(error, config: self.realtimeErrorConfig)
                        return nil
                    }
                }
            }

            var metadatas: [WalletMetaData?] = []
            for await result in group {
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

    public nonisolated var metadata: AsyncValueState<WalletMetaData?> {
        metadataSubject.value
    }

    public nonisolated var metadataPublisher: AnyPublisher<AsyncValueState<WalletMetaData?>, Never> {
        metadataSubject.eraseToAnyPublisher()
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
