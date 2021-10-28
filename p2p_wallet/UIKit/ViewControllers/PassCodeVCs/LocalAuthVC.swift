//
//  LocalAuthVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2020.
//

import Foundation
import THPinViewController
import RxSwift
import LocalAuthentication

class LocalAuthVC: PassCodeVC {
    // MARK: - Properties
    var remainingPinEntries = 3
    var reason: String?
    var isIgnorable = false {
        didSet {
            closeButton.isHidden = !isIgnorable
            isModalInPresentation = !isIgnorable
        }
    }
    var useBiometry = true
    var isBlocked = false {
        didSet {
            blockingView.isHidden = !isBlocked
        }
    }
    @Injected private var accountStorage: KeychainAccountStorage
    var resetPincodeWithASeedPhrasesHandler: (() -> Void)?
    
    var isResetPinCodeWithASeedPhrasesShown = false {
        didSet {
            inputCircleView?.isHidden = isResetPinCodeWithASeedPhrasesShown
            resetPinCodeWithASeedPhraseButton.isHidden = !isResetPinCodeWithASeedPhrasesShown
        }
    }
    
    // MARK: - Additional subviews
    lazy var closeButton = UIButton.close()
        .onTap(self, action: #selector(closeButtonDidTouch))
    
    private lazy var blockingView: UIView = {
        let view = UIView(forAutoLayout: ())
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var resetPinCodeWithASeedPhraseButton: UIView = {
        let button = UILabel(text: L10n.resetPINWithASeedPhrase, textSize: 13, weight: .semibold, textColor: .textSecondary, textAlignment: .center)
            .padding(.init(top: 8, left: 19, bottom: 8, right: 19), backgroundColor: .f6f6f8, cornerRadius: 12)
            .onTap(self, action: #selector(resetPincodeWithASeedPhrases))
        return button
    }()
    
    private var inputCircleView: UIView? {
        embededPinVC.pinView.stackView.arrangedSubviews.first
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // face id, touch id button
        if LABiometryType.isEnabled && useBiometry {
            let button = UIButton(frame: .zero)
            let biometryType = LABiometryType.current
            let icon = biometryType.icon?.withRenderingMode(.alwaysTemplate)
            button.tintColor = .textBlack
            button.setImage(icon, for: .normal)
            leftBottomButton = button
            leftBottomButton?.widthAnchor.constraint(equalToConstant: 50).isActive = true
            leftBottomButton?.widthAnchor.constraint(equalTo: leftBottomButton!.heightAnchor).isActive = true
            leftBottomButton?.addTarget(self, action: #selector(authWithBiometric), for: .touchUpInside)
            authWithBiometric(isAuto: true)
        }
        
        if isIgnorable {
            view.addSubview(closeButton)
            closeButton.autoPinToTopRightCornerOfSuperview(xInset: 16)
        }
        
        embededPinVC.pinView.stackView.insertArrangedSubview(resetPinCodeWithASeedPhraseButton, at: 1)
        resetPinCodeWithASeedPhraseButton.isHidden = true
        
        embededPinVC.pinView.stackView
            .setCustomSpacing(16, after: resetPinCodeWithASeedPhraseButton)
        
        embededPinVC.pinView.addSubview(blockingView)
        blockingView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        blockingView.autoPinEdge(.top, to: .bottom, of: resetPinCodeWithASeedPhraseButton)
        blockingView.isHidden = true
    }
    
    // MARK: - Actions
    @objc func authWithBiometric(isAuto: Bool = false) {
        let myContext = LAContext()
        let myReason = reason ?? L10n.confirmItSYou
        var authError: NSError?
        if myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            if let error = authError {
                print(error)
                return
            }
            myContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: myReason) { (success, _) in
                DispatchQueue.main.sync {
                    if success {
                        self.completion?(true)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else {
            if !isAuto {
                showAlert(title: L10n.warning, message: LABiometryType.current.stringValue + " " + L10n.WasTurnedOff.doYouWantToTurnItOn, buttonTitles: [L10n.turnOn, L10n.cancel], highlightedButtonIndex: 0) { (index) in
                    
                    if index == 0 {
                        if let url = URL.init(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
            }
        }
    }
    
    @objc func resetPincodeWithASeedPhrases() {
        resetPincodeWithASeedPhrasesHandler?()
    }
    
    @objc func closeButtonDidTouch() {
        cancelledCompletion?()
        back()
    }

    // MARK: - Delegate
    override func pinViewController(_ pinViewController: THPinViewController, isPinValid pin: String) -> Bool {
        guard let correctPin = accountStorage.pinCode else {return false}
        if pin == correctPin {
            return true
        } else {
            remainingPinEntries -= 1
            embededPinVC.errorTitle = L10n.wrongPinCodeDAttemptSLeft(remainingPinEntries)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.embededPinVC.errorTitle = nil
            }
            return false
        }
    }
    
    override func userCanRetry(in pinViewController: THPinViewController) -> Bool {
        return remainingPinEntries > 0
    }
}
