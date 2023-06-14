//
//  File.swift
//
//
//  Created by Giang Long Tran on 13/06/2023.
//

import Combine
import Foundation

public class DeviceShareMigrationService {
    let isWeb3AuthUser: AnyPublisher<Bool?, Never>
    let hasDeviceShare: AnyPublisher<Bool, Never>

    let migrationIsAvailableSubject: CurrentValueSubject<Bool, Never> = .init(false)

    public var migrationIsAvailable: AnyPublisher<Bool, Never> { migrationIsAvailableSubject.eraseToAnyPublisher() }

    var subscriptions: [AnyCancellable] = []

    public init(isWeb3AuthUser: AnyPublisher<Bool?, Never>, hasDeviceShare: AnyPublisher<Bool, Never>) {
        self.isWeb3AuthUser = isWeb3AuthUser
        self.hasDeviceShare = hasDeviceShare

        Publishers.CombineLatest(isWeb3AuthUser, hasDeviceShare)
            .map { isWeb3User, hasDeviceShare -> Bool in
                guard let isWeb3User else { return false }

                if isWeb3User, !hasDeviceShare {
                    return true
                } else {
                    return false
                }
            }
            .sink { [weak self] value in
                self?.migrationIsAvailableSubject.value = value
            }
            .store(in: &subscriptions)
    }
}
