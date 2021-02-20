//
//  OnboardingViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

protocol OnboardingScenesFactory {
    func makeCreatePassCodeVC() -> CreatePassCodeVC
    func makeEnableBiometryVC() -> EnableBiometryVC
    func makeEnableNotificationsVC() -> EnableNotificationsVC
    func makeWellDoneVC() -> WellDoneVC
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
    override func viewDidLoad() {
        super.viewDidLoad()
        childNavigationController = BENavigationController()
        
        childNavigationController.isModalInPresentation = true
        present(childNavigationController, animated: true, completion: nil)
        
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
            .subscribe(onNext: {self.navigate(to: $0)})
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func navigate(to scene: OnboardingNavigatableScene) {
        switch scene {
        case .createPincode:
            let pincodeVC = scenesFactory.makeCreatePassCodeVC()
            pincodeVC.disableDismissAfterCompletion = true

            pincodeVC.completion = {_ in
                guard let pincode = pincodeVC.passcode else {return}
                self.viewModel.savePincode(pincode)
            }
            childNavigationController.viewControllers = [pincodeVC]
        case .setUpBiometryAuthentication:
            let biometryVC = scenesFactory.makeEnableBiometryVC()
            childNavigationController.pushViewController(biometryVC, animated: true)
        case .setUpNotifications:
            let enableNotificationsVC = scenesFactory.makeEnableNotificationsVC()
            childNavigationController.pushViewController(enableNotificationsVC, animated: true)
        case .done:
            let vc = scenesFactory.makeWellDoneVC()
            childNavigationController.pushViewController(vc, animated: true)
        case .dismiss:
            dismiss(animated: true, completion: nil)
        }
    }
}
