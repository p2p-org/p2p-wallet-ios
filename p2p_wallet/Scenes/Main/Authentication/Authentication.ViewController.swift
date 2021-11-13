//
//  Authentication.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Foundation
import UIKit
import LocalAuthentication

extension Authentication {
    class ViewController: BaseVC {
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
        private let navigationBar = WLNavigationBar(forAutoLayout: ())
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
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .resetPincodeWithASeedPhrase:
                break
            default:
                break
            }
        }
        
        // MARK: - Actions
        @objc private func cancel() {
            dismiss(animated: true) { [weak self] in
                self?.onCancel?()
            }
        }
        
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
        
        // MARK: - Helpers
        private func authenticationDidComplete() {
            dismiss(animated: true) { [weak self] in
                self?.onSuccess?()
            }
        }
    }
}
