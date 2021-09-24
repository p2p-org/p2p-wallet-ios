//
//  Onboarding.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

extension Onboarding {
    class ViewController: WLIntroVC {
        // MARK: - Dependencies
        @Injected private var viewModel: OnboardingViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        var childNavigationController: BENavigationController!
        var isChildNCPresented = false
        
        // MARK: - Methods
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            if !isChildNCPresented {
                let modalVC = WLIndicatorModalVC()
                modalVC.add(child: childNavigationController, to: modalVC.containerView)
                
                modalVC.isModalInPresentation = true
                present(modalVC, animated: true, completion: nil)
                isChildNCPresented = true
            }
            
            viewModel.navigateNext()
        }
        
        override func setUp() {
            super.setUp()
            // add nc
            childNavigationController = BENavigationController()
            
            // set up
            descriptionLabel.isHidden = false
            titleLabel.text = L10n.congratulations
            descriptionLabel.text = L10n.yourWalletHasBeenSuccessfullyCreated
            
            buttonsStackView.addArrangedSubviews([
                UIView(height: 56),
                UIView(height: 56)
            ])
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
                let pincodeVC = Onboarding.CreatePassCodeVC()
                pincodeVC.disableDismissAfterCompletion = true

                pincodeVC.completion = { [weak self, weak pincodeVC] _ in
                    guard let pincode = pincodeVC?.passcode else {return}
                    self?.viewModel.savePincode(pincode)
                    self?.analyticsManager.log(event: .setupPinKeydown2)
                }
                childNavigationController.viewControllers = [pincodeVC]
            case .setUpBiometryAuthentication:
                let biometryVC = EnableBiometryVC()
                childNavigationController.pushViewController(biometryVC, animated: true)
            case .setUpNotifications:
                let enableNotificationsVC = EnableNotificationsVC()
                childNavigationController.pushViewController(enableNotificationsVC, animated: true)
            case .dismiss:
                dismiss(animated: true, completion: nil)
            default:
                break
            }
        }
    }
}
