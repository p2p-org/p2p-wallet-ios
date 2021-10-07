//
//  ReserveName.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import UIKit
import RxSwift
import Action
import GT3Captcha

extension ReserveName {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Dependencies
        @Injected private var nameService: NameServiceType
        
        // MARK: - Properties
        private var viewModel: ReserveNameViewModelType
        private lazy var manager: GT3CaptchaManager = {
            let manager = GT3CaptchaManager(api1: nameService.captchaAPI1Url, api2: nil, timeout: 10)
            manager.delegate = self
            return manager
        }()
        
        // MARK: - Subviews
        private lazy var textField = UITextField(
            height: 56,
            backgroundColor: .f6f6f8,
            cornerRadius: 12,
            keyboardType: .asciiCapable,
            placeholder: L10n.username,
            placeholderTextColor: .textSecondary,
            autocorrectionType: .no,
            autocapitalizationType: UITextAutocapitalizationType.none,
            spellCheckingType: .no,
            textContentType: .username,
            horizontalPadding: 18,
            rightView: UILabel(text: "".withNameServiceSuffix(), textSize: 17, weight: .semibold, textColor: .textSecondary)
                .padding(.init(only: .right, inset: 18)),
            rightViewMode: .always,
            showClearButton: false
        )
            .border(width: 1, color: .a3a5ba.withAlphaComponent(0.5))
        
        private lazy var verificationLabel = UILabel(text: L10n.useAnyLatinAndSpecialSymbolsOrEmojis, textSize: 15, textColor: .textSecondary, numberOfLines: 0)
        
        private lazy var skipLabel: UILabel = {
            let label = UILabel(
                text: L10n.youCanAlsoThisStepAndReserveAUsernameLater(L10n.skip),
                textSize: 15,
                numberOfLines: 0
            )
            semiboldText([L10n.skip], in: label)
            return label.onTap(self, action: #selector(skipLabelDidTouch))
        }()
        
        private lazy var continueButton: WLButton = .stepButton(type: .blue, label: L10n.continue)
            .onTap(self, action: #selector(continueButtonDidTouch))
        private lazy var skipButton: WLButton = .stepButton(type: .gray, label: L10n.skip.uppercaseFirst)
            .onTap(self, action: #selector(skipButtonDidTouch))
        private lazy var footerLabel: UILabel = {
            let label = UILabel(text: L10n.byContinuingYouAgreeToWalletSAnd(L10n.termsOfUse, L10n.privacyPolicy), textSize: 15, numberOfLines: 0, textAlignment: .center)
            semiboldText([L10n.termsOfUse, L10n.privacyPolicy], in: label)
            return label
        }()
        
        // MARK: - Initializer
        init(viewModel: ReserveNameViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            manager.registerCaptcha(nil)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            textField.delegate = self
            layout()
            bind()
            onTap(self, action: #selector(viewDidTap))
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
                
                BEStackViewSpacing(100)
                continueButton
                
                BEStackViewSpacing(10)
                skipButton
                
                BEStackViewSpacing(20)
                footerLabel
            }
        }
        
        private func bind() {
            viewModel.initializingStateDriver
                .drive(onNext: { [weak self] loadingState in
                    switch loadingState {
                    case .notRequested, .loading:
                        self?.showIndetermineHud()
                    case .loaded:
                        self?.hideHud()
                    case .error:
                        self?.showErrorView(title: L10n.error, description: L10n.somethingWentWrongPleaseTryAgainLater, retryAction: .init(workFactory: {[weak self] _ in
                            self?.viewModel.reload()
                            return .just(())
                        }))
                    }
                })
                .disposed(by: disposeBag)
            
            viewModel.isNameValidLoadableDriver
                .drive(onNext: {[weak self] loadableBool in
                    let textColor: UIColor
                    let text: String?
                    switch loadableBool.state {
                    case .notRequested:
                        textColor = .textSecondary
                        text = L10n.useAnyLatinAndSpecialSymbolsOrEmojis
                    case .loading:
                        textColor = .textSecondary
                        text = L10n.checkingNameSAvailability
                    case .loaded:
                        // valid name
                        if loadableBool.value == true {
                            textColor = .attentionGreen
                            text = L10n.isAvailable(self?.viewModel.currentName ?? L10n.name)
                        } else if self?.viewModel.currentName?.isEmpty == false {
                            textColor = .alert
                            text = L10n.isnTAvailable(self?.viewModel.currentName ?? L10n.name)
                        } else {
                            textColor = .textSecondary
                            text = L10n.useAnyLatinAndSpecialSymbolsOrEmojis
                        }
                    case .error(_):
                        textColor = .alert
                        text = L10n.CouldNotCheckNameSAvailability.pleaseCheckYourInternetConnection
                    }
                    self?.verificationLabel.text = text
                    self?.verificationLabel.textColor = textColor
                })
                .disposed(by: disposeBag)
            
            textField.rx.text
                .distinctUntilChanged()
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .subscribe(onNext: {[weak self] text in
                    self?.viewModel.userDidEnter(name: text)
                })
                .disposed(by: disposeBag)
            
            // button
            viewModel.isNameValidLoadableDriver
                .withLatestFrom(viewModel.initializingStateDriver, resultSelector: {($1, $0)})
                .map { initState, isValid -> Bool in
                    initState == .loaded && isValid.state == .loaded && isValid.value == true
                }
                .drive(continueButton.rx.isEnabled)
                .disposed(by: disposeBag)
        }
        
        @objc func skipLabelDidTouch(gesture: UITapGestureRecognizer) {
            let skipRange = (skipLabel.text! as NSString).range(of: L10n.skip)
            if gesture.didTapAttributedTextInLabel(label: skipLabel, inRange: skipRange) {
                skipButtonDidTouch()
            } else {
                viewDidTap()
            }
        }
        
        @objc func continueButtonDidTouch() {
            endEditing(true)
            manager.startGTCaptchaWith(animated: true)
        }
        
        @objc func skipButtonDidTouch() {
            viewModel.skip()
        }
        
        @objc func viewDidTap() {
            endEditing(true)
        }
    }
}

extension ReserveName.RootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // only allow small latin, hyphens and numbers
        let set = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
            .inverted
        let containsOnlyAllowedCharacters = string.rangeOfCharacter(from: set) == nil
        
        // don't allow 2 hyphens next to each other
        guard let stringRange = Range(range, in: textField.text ?? "") else { return false }
        let updatedText = (textField.text ?? "").replacingCharacters(in: stringRange, with: string)
        let doNotContains2HyphensNextToEachOther = !updatedText.contains("--")
        
        return containsOnlyAllowedCharacters && doNotContains2HyphensNextToEachOther
    }
}

extension ReserveName.RootView: GT3CaptchaManagerDelegate {
    func gtCaptcha(_ manager: GT3CaptchaManager, errorHandler error: GT3Error) {
        UIApplication.shared.showToast(message: "❌ \(error.readableDescription)")
    }
    
    func gtCaptcha(_ manager: GT3CaptchaManager, didReceiveCaptchaCode code: String, result: [AnyHashable: Any]?, message: String?) {
        guard code == "1",
              let geetest_seccode = result?["geetest_seccode"] as? String,
              let geetest_challenge = result?["geetest_challenge"] as? String,
              let geetest_validate = result?["geetest_validate"] as? String
        else {
            return
        }
        viewModel.reserveName(geetest_seccode: geetest_seccode, geetest_challenge: geetest_challenge, geetest_validate: geetest_validate)
    }
    
    func shouldUseDefaultSecondaryValidate(_ manager: GT3CaptchaManager) -> Bool {
        false
    }
    
    func gtCaptcha(_ manager: GT3CaptchaManager, didReceiveSecondaryCaptchaData data: Data?, response: URLResponse?, error: GT3Error?, decisionHandler: @escaping (GT3SecondaryCaptchaPolicy) -> Void) {
        
    }
}

private func semiboldText(_ texts: [String], in label: UILabel) {
    let aStr = NSMutableAttributedString(string: label.text!)
    for text in texts {
        let range = NSString(string: label.text!).range(of: text)
        aStr.addAttribute(.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: range)
        aStr.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: range)
    }
    label.attributedText = aStr
}

private extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
         // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
         let layoutManager = NSLayoutManager()
         let textContainer = NSTextContainer(size: CGSize.zero)
         let textStorage = NSTextStorage(attributedString: label.attributedText!)

         // Configure layoutManager and textStorage
         layoutManager.addTextContainer(textContainer)
         textStorage.addLayoutManager(layoutManager)

         // Configure textContainer
         textContainer.lineFragmentPadding = 0.0
         textContainer.lineBreakMode = label.lineBreakMode
         textContainer.maximumNumberOfLines = label.numberOfLines
         let labelSize = label.bounds.size
         textContainer.size = labelSize

         // Find the tapped character location and compare it to the specified range
         let locationOfTouchInLabel = self.location(in: label)
         let textBoundingBox = layoutManager.usedRect(for: textContainer)
         //let textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                               //(labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
         let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

         //let locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
                                                         // locationOfTouchInLabel.y - textContainerOffset.y);
         let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
         let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
         return NSLocationInRange(indexOfCharacter, targetRange)
     }
}
