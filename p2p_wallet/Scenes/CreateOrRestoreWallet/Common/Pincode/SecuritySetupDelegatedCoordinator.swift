import Combine
import KeyAppUI
import Onboarding
import SwiftUI
import UIKit

final class SecuritySetupDelegatedCoordinator: DelegatedCoordinator<SecuritySetupState> {
    override func buildViewController(for state: SecuritySetupState) -> UIViewController? {
        switch state {
        case .setProtectionLevel:
            return protectionLevelScreen()

        case .createPincode:
            let isInitial = SecuritySetupState.initialState == .createPincode
            return createPincodeScreen(isBackAvailable: !isInitial)

        case let .confirmPincode(pin):
            return confirmPincodeScreen(pin)

        default:
            return nil
        }
    }

    private func protectionLevelScreen() -> UIViewController {
        let viewModel = ProtectionLevelViewModel()
        let view = ProtectionLevelView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        viewModel.setUpPinDidTap
            .sinkAsync { [stateMachine] _ in
                try await stateMachine <- .createPincode
            }
            .store(in: &subscriptions)

        viewModel.authenticatedSuccessfully
            .sinkAsync { [stateMachine] _ in
                try await stateMachine <- .setPincode(pincode: nil, withBiometric: true)
            }
            .store(in: &subscriptions)

        viewModel.viewAppeared
            .sink { [weak self] _ in
                self?.addRightButton(vc: viewController)
            }
            .store(in: &subscriptions)

        return viewController
    }

    private func createPincodeScreen(isBackAvailable: Bool) -> UIViewController {
        let viewModel = PincodeViewModel(state: .create, isBackAvailable: isBackAvailable)
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

        viewModel.back
            .sinkAsync { [stateMachine] _ in
                try await stateMachine <- .back
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
            .sinkAsync { [stateMachine] pincode, withBiometric in
                try await stateMachine <- .setPincode(pincode: pincode, withBiometric: withBiometric)
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
