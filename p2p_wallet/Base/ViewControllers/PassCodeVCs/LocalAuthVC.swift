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
    lazy var closeButton = UIButton.close()
        .onTap(self, action: #selector(back))
    
    private lazy var blockingView: UIView = {
        let view = UIView(forAutoLayout: ())
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()
    
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
    let accountStorage: KeychainAccountStorage
    
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
        super.init()
    }
    
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
        
        view.addSubview(blockingView)
        blockingView.autoPinEdgesToSuperviewEdges()
        blockingView.isHidden = true
    }
    
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
