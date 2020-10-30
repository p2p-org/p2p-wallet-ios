//
//  EnableBiometryVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import LocalAuthentication

class EnableBiometryVC: BaseVC {
    enum Error: Swift.Error {
        case unknown
    }
    
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    lazy var stackView = UIStackView(axis: .vertical, spacing: 36, alignment: .center, distribution: .fill)
    
    lazy var useFaceIdButton = WLButton.stepButton(type: .main, label: L10n.useFaceId)
        .onTap(self, action: #selector(buttonUseFaceIdDidTouch))
    
    lazy var doThisLaterButton = WLButton.stepButton(type: .sub, label: L10n.doThisLater)
        .onTap(self, action: #selector(buttonDoThisLaterDidTouch))
    
    override func setUp() {
        super.setUp()
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 0, left: 20, bottom: 16, right: 20))
        
        let label = UILabel(text: L10n.useYourFaceIDForQuickAccess, textSize: 21, weight: .medium, numberOfLines: 0, textAlignment: .center)
        let imageView = UIImageView(width: 64, height: 64, image: .faceId)
        let spacer1 = UIView.spacer
        let spacer2 = UIView.spacer
        
        stackView.addArrangedSubview(spacer1)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(spacer2)
        
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
        
        let buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
        buttonStackView.addArrangedSubview(useFaceIdButton)
        buttonStackView.addArrangedSubview(doThisLaterButton)
        stackView.addArrangedSubview(buttonStackView)
        buttonStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40)
            .isActive = true
    }
    
    @objc func buttonUseFaceIdDidTouch() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in

                DispatchQueue.main.async {
                    if success {
                        self?.handleIsBiometryEnabled(true)
                    } else {
                        self?.showError(error ?? Error.unknown)
                    }
                }
            }
        } else {
            // no biometry
        }
    }
    
    @objc func buttonDoThisLaterDidTouch() {
        handleIsBiometryEnabled(false)
    }
    
    func handleIsBiometryEnabled(_ enabled: Bool) {
        Defaults.isBiometryEnabled = enabled
        Defaults.didSetEnableBiometry = true
        
    }
}
