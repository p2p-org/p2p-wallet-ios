//
//  OnboardingViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

protocol OnboardingScenesFactory {
    func makeOnboardingCreatePassCodeVC() -> OnboardingCreatePassCodeVC
    func makeEnableBiometryVC() -> EnableBiometryVC
    func makeEnableNotificationsVC() -> EnableNotificationsVC
}

class OnboardingViewController: WLIntroVC {
    // MARK: - Properties
    let viewModel: OnboardingViewModel
    let scenesFactory: OnboardingScenesFactory
    var childNavigationController: BENavigationController!
    
    // MARK: - Initializer
    init(viewModel: OnboardingViewModel, scenesFactory: OnboardingScenesFactory)
    {
        self.scenesFactory = scenesFactory
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - Methods
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        childNavigationController = BENavigationController()
        
        let modalVC = WLIndicatorModalVC()
        modalVC.add(child: childNavigationController, to: modalVC.containerView)
        
        modalVC.isModalInPresentation = true
        present(modalVC, animated: true, completion: nil)
        
        viewModel.navigateNext()
    }
    
    override func setUp() {
        super.setUp()
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
        viewModel.navigationSubject
            .subscribe(onNext: {[unowned self] in self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: OnboardingNavigatableScene) {
        switch scene {
        case .createPincode:
            let pincodeVC = scenesFactory.makeOnboardingCreatePassCodeVC()
            pincodeVC.disableDismissAfterCompletion = true

            pincodeVC.completion = { [weak self, weak pincodeVC] _ in
                guard let pincode = pincodeVC?.passcode else {return}
                self?.viewModel.savePincode(pincode)
                self?.viewModel.analyticsManager.log(event: .setupPinKeydown2)
            }
            childNavigationController.viewControllers = [pincodeVC]
        case .setUpBiometryAuthentication:
            let biometryVC = scenesFactory.makeEnableBiometryVC()
            childNavigationController.pushViewController(biometryVC, animated: true)
        case .setUpNotifications:
            let enableNotificationsVC = scenesFactory.makeEnableNotificationsVC()
            childNavigationController.pushViewController(enableNotificationsVC, animated: true)
        case .dismiss:
            dismiss(animated: true, completion: nil)
        }
    }
}
