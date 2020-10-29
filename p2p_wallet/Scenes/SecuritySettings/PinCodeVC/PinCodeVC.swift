//
//  PinCodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation

class PinCodeVC: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    override var padding: UIEdgeInsets {
        var padding = super.padding
        padding.top += 78
        padding.left = 20
        padding.right = 20
        return padding
    }
    
    let numberOfDigits = 6
    
    lazy var pinCodeTextField: PinCodeTextField = {
        let tf = PinCodeTextField(forAutoLayout: ())
        tf.numberOfDigits = numberOfDigits
        return tf
    }()
    
    lazy var nextButton = WLButton.stepButton(type: .main, label: L10n.next.uppercaseFirst)
    
    override func setUp() {
        super.setUp()
        let label = UILabel(text: L10n.createAPINCodeToProtectYourWallet, textSize: 21, weight: .semibold, numberOfLines: 2, textAlignment: .center)
        
        stackView.spacing = 60
        stackView.alignment = .center
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(pinCodeTextField)
        
        view.addSubview(nextButton)
        nextButton.autoPinEdge(toSuperviewSafeArea: .leading, withInset: padding.left)
        nextButton.autoPinEdge(toSuperviewSafeArea: .trailing, withInset: padding.right)
        let constraint = AvoidingKeyboardLayoutConstraint(item: view.safeAreaLayoutGuide, attribute: .bottom, relatedBy: .equal, toItem: nextButton, attribute: .bottom, multiplier: 1, constant: 16)
        constraint.isActive = true
        constraint.observeKeyboardHeight()
    }
    
    override func bind() {
        super.bind()
        pinCodeTextField.text.map {$0.count == 6}
            .asDriver(onErrorJustReturn: false)
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
}
