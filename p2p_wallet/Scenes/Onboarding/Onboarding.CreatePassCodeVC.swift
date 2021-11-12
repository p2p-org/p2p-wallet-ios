//
//  OnboardingCreatePassCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/03/2021.
//

import Foundation
import Resolver

extension Onboarding {
    class PasscodeVC: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: OnboardingViewModelType
        
        // MARK: - Properties
        /// current pin code for confirming, if nil, the scene is create pincode
        private let currentPincode: UInt?
        override var title: String? {
            didSet {
                navigationBar.titleLabel.text = title
            }
        }
        
        // MARK: - Subviews
        private lazy var navigationBar = WLNavigationBar(forAutoLayout: ())
        private lazy var pincodeView = WLPinCodeView(correctPincode: currentPincode)
        
        // MARK: - Initializer
        init(currentPincode: UInt? = nil) {
            self.currentPincode = currentPincode
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            if isConfirmingPincode() {
                navigationBar.backButton.onTap(self, action: #selector(back))
            } else {
                navigationBar.backButton.onTap(self, action: #selector(cancelOnboarding))
            }
            
            let pincodeWrapperView = UIView(forAutoLayout: ())
            view.addSubview(pincodeWrapperView)
            pincodeWrapperView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            pincodeWrapperView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            
            pincodeWrapperView.addSubview(pincodeView)
            pincodeView.autoCenterInSuperview()
            
            pincodeView.onSuccess = { [weak self] pincode in
                guard let self = self, let pincode = pincode else {return}
                
                // confirm pincode scene
                if self.isConfirmingPincode() {
                    self.viewModel.savePincode(String(pincode))
                }
                
                // create pincode scene
                else {
                    self.viewModel.confirmPincode(pincode)
                }
            }
        }
        
        // MARK: - Actions
        @objc private func cancelOnboarding() {
            viewModel.cancelOnboarding()
        }
        
        // MARK: - Helpers
        private func isConfirmingPincode() -> Bool {
            currentPincode != nil
        }
    }
}
