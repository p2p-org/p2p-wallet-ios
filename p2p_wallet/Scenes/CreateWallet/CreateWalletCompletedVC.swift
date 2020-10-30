//
//  CreateWalletCompletedVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class CreateWalletCompletedVC: IntroVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    // MARK: - Subviews
    lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
        return stackView
    }()
    lazy var nextButton = WLButton.stepButton(type: .main, label: L10n.next.uppercaseFirst)
        .onTap(self, action: #selector(buttonNextDidTouch))
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = false
        titleLabel.text = L10n.congratulations
        descriptionLabel.text = L10n.yourWalletHasBeenSuccessfullyCreated
        
        stackView.addArrangedSubview(buttonStackView)
        buttonStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60)
            .isActive = true
        
        buttonStackView.addArrangedSubview(nextButton)
    }
    
    // MARK: - Actions
    @objc func buttonNextDidTouch() {
        let vc = PinCodeVC()
        vc.completion = {_ in
            let vc = EnableBiometryVC()
            let nc = BENavigationController(rootViewController: vc)
            UIApplication.shared.changeRootVC(to: nc)
        }
        let nc = BENavigationController(rootViewController: vc)
        UIApplication.shared.changeRootVC(to: nc)
    }
}
