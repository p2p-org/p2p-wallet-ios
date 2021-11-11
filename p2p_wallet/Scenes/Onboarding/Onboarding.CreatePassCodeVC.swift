//
//  OnboardingCreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/03/2021.
//

import Foundation
import Resolver

extension Onboarding {
    class CreatePassCodeVC: p2p_wallet.CreatePassCodeVC {
        @Injected private var viewModel: OnboardingViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        override func viewDidLoad() {
            super.viewDidLoad()
            backButton
                .onTap(self, action: #selector(cancelOnboarding))
        }
        
        override func showConfirmPassCodeVC() {
            super.showConfirmPassCodeVC()
            analyticsManager.log(event: .setupPinKeydown1)
        }
        
        @objc func cancelOnboarding() {
            viewModel.cancelOnboarding()
        }
    }
    
    class PasscodeVC: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        @Injected private var viewModel: OnboardingViewModelType
        private lazy var navigationBar = WLNavigationBar(forAutoLayout: ())
        private lazy var pincodeView = WLPinCodeView(correctPincode: currentPincode)
        
        private let currentPincode: UInt?
        
        init(currentPincode: UInt? = nil) {
            self.currentPincode = currentPincode
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            navigationBar.backButton.onTap(self, action: #selector(cancelOnboarding))
            
            view.addSubview(pincodeView)
            pincodeView.autoCenterInSuperview()
            
            pincodeView.onSuccess = { [weak self] pincode in
                guard let pincode = pincode else {return}
                
                // if this vc is CreatePincode
                if self?.currentPincode == nil {
                    self?.viewModel.confirmPincode(pincode)
                }
                
                // confirm pincode
                else {
                    self?.viewModel.savePincode(String(pincode))
                }
            }
        }
        
        @objc private func cancelOnboarding() {
            viewModel.cancelOnboarding()
        }
    }
}
