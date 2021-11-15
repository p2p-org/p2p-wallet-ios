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
        @Injected private var viewModel: OnboardingViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private lazy var childNavigationController = BENavigationController()
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            add(child: childNavigationController, to: view)
            viewModel.navigateNext()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
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
                createPincodeVC.onSuccess = {[weak self] pincode in
                    self?.viewModel.savePincode(String(pincode))
                }
                createPincodeVC.onCancel = {[weak self] in
                    self?.viewModel.cancelOnboarding()
                }
                childNavigationController.viewControllers = [createPincodeVC]
            case .setUpBiometryAuthentication:
                let biometryVC = EnableBiometryVC()
                childNavigationController.pushViewController(biometryVC, animated: true)
            case .setUpNotifications:
                let enableNotificationsVC = EnableNotificationsVC()
                childNavigationController.pushViewController(enableNotificationsVC, animated: true)
            case .dismiss:
                dismiss(animated: true, completion: nil)
            case .none:
                break
            }
        }
    }
}
