//
//  ReserveName.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import UIKit
import RxSwift

extension ReserveName {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        @Injected private var viewModel: ReserveNameViewModelType
        
        // MARK: - Subviews
        private lazy var textField = UITextField(
            height: 56,
            backgroundColor: .f6f6f8,
            cornerRadius: 12,
            keyboardType: .asciiCapableNumberPad,
            placeholder: L10n.username,
            placeholderTextColor: .textSecondary,
            autocorrectionType: .no,
            autocapitalizationType: UITextAutocapitalizationType.none,
            spellCheckingType: .no,
            textContentType: .username,
            horizontalPadding: 18,
            rightView: UILabel(text: ".p2p.sol", textSize: 17, weight: .semibold, textColor: .textSecondary)
                .padding(.init(only: .right, inset: 18)),
            rightViewMode: .always,
            showClearButton: false
        )
            .border(width: 1, color: .a3a5ba.withAlphaComponent(0.5))
        
        private lazy var verificationLabel = UILabel(text: L10n.youCanAlsoThisStepAndReserveAUsernameLater(L10n.skip), textSize: 15, numberOfLines: 0)
        
        private lazy var skipLabel: UILabel = {
            let label = UILabel(
                text: L10n.youCanAlsoThisStepAndReserveAUsernameLater(L10n.skip),
                textSize: 15,
                numberOfLines: 0
            )
            semiboldText(L10n.skip, in: label)
            return label.onTap(self, action: #selector(skipLabelDidTouch))
        }()
        
        private lazy var continueButton: WLButton = .stepButton(type: .blue, label: L10n.continue)
            .onTap(self, action: #selector(continueButtonDidTouch))
        private lazy var skipButton: WLButton = .stepButton(type: .sub, label: L10n.skip)
            .onTap(self, action: #selector(skipButtonDidTouch))
        private lazy var footerLabel: UILabel = .init(text: L10n.byContinuingYouAgreeToWalletSAnd(L10n.termsOfUse, L10n.privacyPolicy), textSize: 15, numberOfLines: 0, textAlignment: .center)
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
        }
        
        // MARK: - Layout
        private func layout() {
            stackView.spacing = 15
            stackView.addArrangedSubviews {
                UILabel(
                    text:
                        L10n.YouCanReceiveAndSendTokensUsingYourP2PUsernameOrLink.alsoUsersWhoKnowYourURLOrUsernameCanSendYouAnyTokenEvenIfYouDonTHaveItInYourWalletsList,
                    textSize: 15,
                    numberOfLines: 0
                )
                textField
                
                BEStackViewSpacing(8)
                verificationLabel
                
                BEStackViewSpacing(20)
                UIView.defaultSeparator()
                
                BEStackViewSpacing(20)
                skipLabel
                
                UIView.spacer
                
                continueButton
                
                BEStackViewSpacing(10)
                skipButton
                
                BEStackViewSpacing(20)
                footerLabel
            }
        }
        
        private func bind() {
            
        }
        
        @objc func skipLabelDidTouch() {
            
        }
        
        @objc func continueButtonDidTouch() {
            
        }
        
        @objc func skipButtonDidTouch() {
            
        }
    }
}

private func semiboldText(_ text: String, in label: UILabel) {
    let aStr = NSMutableAttributedString(string: label.text!)
    let range = NSString(string: label.text!).range(of: text)
    aStr.addAttribute(.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: range)
    aStr.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: range)
    label.attributedText = aStr
}
