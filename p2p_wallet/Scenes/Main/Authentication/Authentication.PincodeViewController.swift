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
        
        // MARK: - Constants
        #if DEBUG
        let lockingTimeInSeconds = 10 // 10 seconds
        #else
        let lockingTimeInSeconds = 15 * 60 // 15 minutes
        #endif
        
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
        var didTapResetPincodeWithASeedPhraseButton: (() -> Void)?
        
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
        private lazy var resetPinCodeWithASeedPhraseButton: UIView = {
            let button = UILabel(text: L10n.resetPINWithASeedPhrase, textSize: 13, weight: .semibold, textColor: .textSecondary, textAlignment: .center)
                .padding(.init(top: 8, left: 19, bottom: 8, right: 19), backgroundColor: .f6f6f8, cornerRadius: 12)
                .onTap(self, action: #selector(resetPincodeWithASeedPhrase))
            button.isHidden = true
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
            pincodeView.autoPinEdge(toSuperviewEdge: .leading, withInset: 20, relation: .greaterThanOrEqual)
            pincodeView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20, relation: .greaterThanOrEqual)
            
            pincodeView.onSuccess = {[weak self] _ in
                self?.authenticationDidComplete()
            }
            
            pincodeView.onFailedAndExceededMaxAttemps = {[weak self] in
                self?.numpadDidLock()
            }
            
            // reset pincode with a seed phrase
            pincodeView.addSubview(resetPinCodeWithASeedPhraseButton)
            resetPinCodeWithASeedPhraseButton.autoPinEdge(.top, to: .bottom, of: pincodeView.errorLabel, withOffset: 10)
            resetPinCodeWithASeedPhraseButton.autoAlignAxis(toSuperviewAxis: .vertical)
        }
        
        // MARK: - Actions
        func reset() {
            pincodeView.reset()
            pincodeView.stackViewSpacing = 68
            resetPinCodeWithASeedPhraseButton.isHidden = true
        }
        
        @objc private func resetPincodeWithASeedPhrase() {
            didTapResetPincodeWithASeedPhraseButton?()
        }
        
        @objc private func authWithBiometric() {
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
        
        private func numpadDidLock() {
            isIgnorable = false
            resetPinCodeWithASeedPhraseButton.isHidden = false
            
            var secondsLeft = lockingTimeInSeconds
            
            pincodeView.stackViewSpacing = 108
            
            // Count down to next
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                secondsLeft -= 1
                
                let minutesAndSeconds = secondsToMinutesSeconds(seconds: secondsLeft)
                let minutes = minutesAndSeconds.0
                let seconds = minutesAndSeconds.1
                
                self?.pincodeView.errorLabel.text = L10n.weVeLockedYourWalletTryAgainIn("\(minutes) \(L10n.minutes) \(seconds) \(L10n.seconds)") + " " + L10n.orResetItWithASeedPhrase
                
                if secondsLeft == 0 {
                    self?.reset()
                    timer.invalidate()
                }
            }
        }
    }
}

private func secondsToMinutesSeconds (seconds: Int) -> (Int, Int) {
    return ((seconds % 3600) / 60, (seconds % 3600) % 60)
}
