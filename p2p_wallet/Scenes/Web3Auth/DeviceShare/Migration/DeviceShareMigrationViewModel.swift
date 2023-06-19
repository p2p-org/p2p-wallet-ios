//
//  DeviceShareMigrationViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import Combine
import Foundation
import Onboarding
import Resolver

class DeviceShareMigrationViewModel: BaseViewModel, ObservableObject {
    @Injected var notificationService: NotificationService

    @Injected var deviceShareManager: DeviceShareManager
    @Injected var walletMetadataService: WalletMetadataService
    @Injected var userWalletManager: UserWalletManager
    @Injected var migrationService: DeviceShareMigrationService

    let facade: TKeyFacade

    @Published var title: String = "Updating your authorization device"

    let action = PassthroughSubject<Action, Never>()

    init(facade: TKeyFacade) {
        self.facade = facade
    }

    func start() async {
        do {
            guard let ethAddress = userWalletManager.wallet?.ethAddress else {
                throw Error.unauthorized
            }

            try await migrationService.migrate(
                on: facade,
                for: ethAddress,
                deviceShareStorage: deviceShareManager,
                metadataService: walletMetadataService
            )

            action.send(.finish)
        } catch {
            action.send(.error(error))
        }
    }
}

extension DeviceShareMigrationViewModel {
    enum Action {
        case finish
        case error(Swift.Error)
    }

    enum Error: Swift.Error {
        case unauthorized
    }
}
