import Combine
import KeyAppUI
import Onboarding
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
        let viewModel = PincodeViewModel(state: .create, isBackAvailable: false)
        let viewController = PincodeViewController(viewModel: viewModel)

        viewModel.infoDidTap
            .sink { [weak self] _ in
                self?.openInfo()
            }
            .store(in: &subscriptions)

        viewModel.confirmPin
            .sinkAsync { [stateMachine] pincode in
                try await stateMachine <- .confirmPincode(pincode: pincode)
            }
            .store(in: &subscriptions)

        return viewController
    }

    private func confirmPincodeScreen(_ pincode: String) -> UIViewController {
        let viewModel = PincodeViewModel(state: .confirm(pin: pincode))
        let viewController = PincodeViewController(viewModel: viewModel)

        viewModel.infoDidTap
            .sink { [weak self] _ in
                self?.openInfo()
            }
            .store(in: &subscriptions)

        viewModel.openMain
            .sinkAsync { [stateMachine] pincode in
                try await stateMachine <- .setPincode(pincode: pincode)
            }
            .store(in: &subscriptions)

        viewModel.back
            .sinkAsync { [stateMachine] _ in
                try await stateMachine <- .back
            }
            .store(in: &subscriptions)

        return viewController
    }

    private func addRightButton(vc: UIViewController) {
        let infoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        infoButton.addTarget(self, action: #selector(openInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    @objc private func openInfo() {
        let vc = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(vc, animated: true)
    }
}
