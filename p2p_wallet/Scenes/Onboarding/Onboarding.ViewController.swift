//
//  Onboarding.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

extension Onboarding {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: OnboardingViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType

        // MARK: - Properties

        private lazy var childNavigationController = UINavigationController()

        // MARK: - Initializer

        init(viewModel: OnboardingViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()
            add(child: childNavigationController, to: view)
            viewModel.navigateNext()
        }

        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .createPincode:
                let createPincodeVC = WLCreatePincodeVC(
                    createPincodeTitle: L10n.setUpAWalletPIN,
                    confirmPincodeTitle: L10n.confirmYourWalletPIN
                )
                createPincodeVC.onSuccess = { [weak self] pincode in
                    self?.viewModel.savePincode(String(pincode))
                }
                createPincodeVC.onCancel = { [weak self] in
                    self?.viewModel.cancelOnboarding()
                }
                childNavigationController.viewControllers = [createPincodeVC]
            case .setUpBiometryAuthentication:
                askForEnablingBiometry()
            case .setUpNotifications:
                let enableNotificationsVC = EnableNotificationsVC(viewModel: viewModel)
                childNavigationController.pushViewController(enableNotificationsVC, animated: true)
            case .dismiss:
                dismiss(animated: true, completion: nil)
            case .none:
                break
            }
        }

        // MARK: - Actions

        private func askForEnablingBiometry() {
            // form actions
            let allowAction = UIAlertAction(title: L10n.allow, style: .default) { [weak self] _ in
                self?.viewModel.authenticateAndEnableBiometry(errorHandler: nil)
            }
            allowAction.setValue(UIColor.h5887ff, forKey: "titleTextColor")

            let cancelAction = UIAlertAction(title: L10n.donTAllow, style: .destructive) { [weak self] _ in
                self?.viewModel.enableBiometryLater()
            }

            // show alert
            let biometryType = viewModel.getBiometryType().stringValue
            showAlert(
                title: L10n.doYouWantToAllowP2PWalletToUse(biometryType),
                message: L10n.p2PWalletUsesToRestrictUnauthorizedUsersFromAccessingTheApp(biometryType),
                actions: [
                    cancelAction,
                    allowAction,
                ]
            )
        }
    }
}
