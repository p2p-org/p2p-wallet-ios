//
//  File.swift
//
//
//  Created by Giang Long Tran on 13/06/2023.
//

import Combine
import Foundation
import KeyAppKitCore

public class DeviceShareMigrationService {
    let errorObserver: ErrorObserver
    let isMigrationAvailableSubject: CurrentValueSubject<Bool, Never> = .init(false)
    var subscriptions: [AnyCancellable] = []

    public init(
        isWeb3AuthUser: AnyPublisher<Bool?, Never>,
        hasDeviceShare: AnyPublisher<Bool, Never>,
        errorObserver: ErrorObserver
    ) {
        self.errorObserver = errorObserver

        Publishers.CombineLatest(isWeb3AuthUser, hasDeviceShare)
            .map(Self.isMigrationAvailable)
            .sink { [weak self] value in
                self?.isMigrationAvailableSubject.value = value
            }
            .store(in: &subscriptions)
    }

    public var isMigrationAvailable: Bool {
        isMigrationAvailableSubject.value
    }

    public var isMigrationAvailablePublisher: AnyPublisher<Bool, Never> {
        isMigrationAvailableSubject.eraseToAnyPublisher()
    }

    /// Start migration of device share. The old share in old device will be invalid.
    public func migrate(
        on facade: TKeyFacade,
        for userEthAddress: String,
        deviceShareStorage: DeviceShareManager,
        metadataService: WalletMetadataService
    ) async throws {
        guard isMigrationAvailable else {
            throw errorObserver.watchError(Error.migrationIsNotAllowed)
        }

        // Ensure that user recently has logged.
        guard let ethAddress = await facade.ethAddress else {
            throw errorObserver.watchError(Error.unauthorized)
        }

        // Ensure that eth address of recent logged user is the same with wallet torus eth address.
        guard ethAddress == userEthAddress else {
            throw errorObserver.watchError(Error.ethAddressesAreDifference)
        }
        
        guard var currentMetadata = metadataService.metadata.value else {
            throw errorObserver.watchError(Error.metadataError)
        }

        // Update metadata
        currentMetadata.deviceName = Device.currentDevice()
        let serializedMetadata = try currentMetadata.serialize()
        guard let serializedMetadataStr = String(data: serializedMetadata, encoding: .utf8) else {
            throw errorObserver.watchError(Error.metadataError)
        }

        // Request a new device share for current device
        let result = try await facade.refreshDeviceShare(userData: serializedMetadataStr)

        // Save new device share to current device
        deviceShareStorage.save(deviceShare: result.share)
    }

    /// Static method for determine availibitly of device share migration.
    static func isMigrationAvailable(isWeb3User: Bool?, hasDeviceShare: Bool) -> Bool {
        guard let isWeb3User else { return false }

        if isWeb3User, !hasDeviceShare {
            return true
        } else {
            return false
        }
    }
}

public extension DeviceShareMigrationService {
    enum Error: Swift.Error {
        case unauthorized
        case migrationIsNotAllowed
        case ethAddressesAreDifference
        case metadataError
    }
}
