import Combine
import Onboarding
import Resolver
import SwiftUI
import UIKit

final class SecuritySetupDelegatedCoordinator: DelegatedCoordinator<SecuritySetupState> {

    override func buildViewController(for state: SecuritySetupState) -> UIViewController? {
        switch state {
        case .createPincode:
            return createPincodeScreen()
        case let .confirmPincode(pin):
            return confirmPincodeScreen(pin)
        default:
            return nil
        }
    }

    private func createPincodeScreen() -> UIViewController {
        let viewModel = PincodeViewModel(state: .create, isBackAvailable: false, successNotification: "")
        let viewController = PincodeViewController(viewModel: viewModel)

        viewModel.confirmPin
            .sinkAsync { [stateMachine] pincode in
                try await stateMachine <- .confirmPincode(pincode: pincode)
            }
            .store(in: &subscriptions)

        return viewController
    }

    private func confirmPincodeScreen(_ pincode: String) -> UIViewController {
        let viewModel = PincodeViewModel(
            state: .confirm(pin: pincode, askBiometric: true),
            isBackAvailable: true,
            successNotification: L10n._️GreatYourNewPINIsSet
        )
        let viewController = PincodeViewController(viewModel: viewModel)

        viewModel.openMain
            .sinkAsync { [stateMachine] pincode, isBiometryEnabled in
                try await stateMachine <- .setPincode(pincode: pincode, isBiometryEnabled: isBiometryEnabled)
            }
            .store(in: &subscriptions)

        viewModel.back
            .sinkAsync { [stateMachine] _ in try await stateMachine <- .back }
            .store(in: &subscriptions)

        return viewController
    }
}
