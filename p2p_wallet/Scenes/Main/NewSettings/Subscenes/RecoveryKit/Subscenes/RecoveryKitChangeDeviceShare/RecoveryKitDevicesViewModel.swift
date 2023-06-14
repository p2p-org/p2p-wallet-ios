//
//  RecoveryKitDevicesViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 13/06/2023.
//

import Foundation
import Resolver

class RecoveryKitDevicesViewModel: BaseViewModel, ObservableObject {
    @Injected var metadataService: WalletMetadataService

    @Published var currentDevice: String = ""
    @Published var oldDevice: String = ""

    override init() {
        super.init()

        metadataService
            .metadataPublisher
            .sink { [weak self] metadataState in
                guard let self = self else { return }
                guard let metadata = metadataState.value else {
                    self.currentDevice = L10n.error
                    self.oldDevice = L10n.error
                    return
                }

                self.currentDevice = Device.getDeviceNameFromIdentifier(Device.currentDevice())
                self.oldDevice = Device.getDeviceNameFromIdentifier(metadata.deviceName)
            }
            .store(in: &subscriptions)
    }
}
