//
//  Authentication.PincodeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2021.
//

import Foundation
import LocalAuthentication

extension Authentication {
    class PincodeViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        @Injected private var viewModel: AuthenticationViewModelType
        
        // MARK: - Properties
        override var title: String? {
            didSet {
                navigationBar.titleLabel.text = title
            }
        }
        
        var isIgnorable: Bool = false {
            didSet {
                navigationBar.backButton.isHidden = !isIgnorable
            }
        }
        
        var useBiometry: Bool = true {
            didSet {
                biometryButton?.isHidden = !useBiometry
            }
        }
        
        // MARK: - Callbacks
        var onSuccess: (() -> Void)?
        var onCancel: (() -> Void)?
        
        // MARK: - Subviews
        fileprivate let navigationBar = WLNavigationBar(forAutoLayout: ())
        private lazy var pincodeView = WLPinCodeView(
            correctPincode: viewModel.getCurrentPincode() == nil ? nil: UInt(viewModel.getCurrentPincode()!),
            maxAttemptsCount: 3,
            bottomLeftButton: biometryButton
        )
        private lazy var biometryButton: UIButton? = {
            let biometryType = LABiometryType.current
            guard let icon = biometryType.icon?.withRenderingMode(.alwaysTemplate) else {
                return nil
            }
            let button = UIButton(frame: .zero)
            button.tintColor = .textBlack
            button.setImage(icon, for: .normal)
            button.onTap(self, action: #selector(authWithBiometric))
            return button
        }()
        
        // MARK: - Methods
        override func viewDidLoad() {
            super.viewDidLoad()
            if useBiometry {
                authWithBiometric()
            }
        }
        
        override func setUp() {
            super.setUp()
            // navigation bar
            if isIgnorable {
                navigationBar.backButton.onTap(self, action: #selector(cancel))
            }
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            // pincode view
            let wrappedView = UIView(forAutoLayout: ())
            view.addSubview(wrappedView)
            wrappedView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            wrappedView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            
            wrappedView.addSubview(pincodeView)
            pincodeView.autoCenterInSuperview()
            
            pincodeView.onSuccess = {[weak self] _ in
                self?.authenticationDidComplete()
            }
        }
        
        // MARK: - Actions
        @objc func authWithBiometric() {
            let myContext = LAContext()
            var authError: NSError?
            if myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                if let error = authError {
                    print(error)
                    return
                }
                myContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: L10n.confirmItSYou) { (success, _) in
                    guard success else {return}
                    DispatchQueue.main.sync { [weak self] in
                        self?.authenticationDidComplete()
                    }
                }
            } else {
                showAlert(title: L10n.warning, message: LABiometryType.current.stringValue + " " + L10n.WasTurnedOff.doYouWantToTurnItOn, buttonTitles: [L10n.turnOn, L10n.cancel], highlightedButtonIndex: 0) { (index) in
                    
                    if index == 0 {
                        if let url = URL.init(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
            }
        }
        
        @objc private func cancel() {
            onCancel?()
        }
        
        private func authenticationDidComplete() {
            onSuccess?()
        }
    }

}
