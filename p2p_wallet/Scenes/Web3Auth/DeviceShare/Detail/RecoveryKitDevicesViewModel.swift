import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Onboarding
import Resolver

class RecoveryKitDevicesViewModel: BaseViewModel, ObservableObject {
    @Injected var metadataService: WalletMetadataService
    @Injected var deviceShareMigrationService: DeviceShareMigrationService

    @Published var currentDevice: String = ""
    @Published var oldDevice: String = ""

    let action = PassthroughSubject<Action, Never>()

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

    func setup() {
        guard deviceShareMigrationService.isMigrationAvailable else { return }
        action.send(.setup)
    }
}

extension RecoveryKitDevicesViewModel {
    enum Action {
        case setup
    }
}
