//
//  EnterPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2020.
//

import Foundation
import UITextView_Placeholder
import SubviewAttachingTextView
import RxSwift
import RxCocoa

class EnterPhrasesVC: BaseVStackVC {
    override var padding: UIEdgeInsets {.init(all: 20)}
    
    let error = BehaviorRelay<Error?>(value: nil)
    
    lazy var textView = WLPhrasesTextView()
    
    lazy var errorLabel = UILabel(textColor: .alert, numberOfLines: 0, textAlignment: .center)
    
    lazy var tabBar: TabBar = {
        let tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
        tabBar.backgroundColor = .h2f2f2f
        tabBar.stackView.addArrangedSubviews([
            pasteButton,
            UIView.spacer,
            nextButton
        ])
        return tabBar
    }()
    
    lazy var nextButton = WLButton(backgroundColor: .h5887ff, cornerRadius: 12, label: L10n.done, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .white, contentInsets: .init(x: 16, y: 10))
        .onTap(self, action: #selector(buttonNextDidTouch))
    lazy var pasteButton = WLButton(backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12, label: L10n.paste, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .white, contentInsets: .init(x: 16, y: 10))
        .onTap(self, action: #selector(buttonPasteDidTouch))
    lazy var retryButton = WLButton.stepButton(type: .black, label: L10n.resetAndTryAgain)
        .onTap(self, action: #selector(resetAndTryAgainButtonDidTouch))
    
    lazy var descriptionLabel = UILabel(text: L10n.enterASeedPhraseFromYourAccount, textSize: 17, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
    
    let restoreWalletViewModel: RestoreWalletViewModel
    init(restoreWalletViewModel: RestoreWalletViewModel) {
        self.restoreWalletViewModel = restoreWalletViewModel
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        title = L10n.enterSecurityKeys
        stackView.addArrangedSubviews([
            textView
                .padding(.init(all: 10), backgroundColor: .lightGrayBackground, cornerRadius: 16)
                .border(width: 1, color: .a3a5ba),
            BEStackViewSpacing(30),
            errorLabel
        ])
        
        // tabBar
        view.addSubview(tabBar)
        tabBar.autoPinEdge(toSuperviewEdge: .leading)
        tabBar.autoPinEdge(toSuperviewEdge: .trailing)
        tabBar.autoPinBottomToSuperViewAvoidKeyboard()
        
        view.addSubview(descriptionLabel)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        descriptionLabel.autoPinEdge(.bottom, to: .top, of: tabBar, withOffset: -20)
        
        view.addSubview(retryButton)
        retryButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
        retryButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        retryButton.autoPinEdge(.bottom, to: .top, of: descriptionLabel, withOffset: -30)
        
        view.removeGestureRecognizer(tapGesture)
        
        textView.becomeFirstResponder()
        textView.keyboardDismissMode = .onDrag
        textView.forwardedDelegate = self
    }
    
    override func bind() {
        super.bind()
        Observable.combineLatest(
            textView.rx.text
                .map {_ in !self.textView.getPhrases().isEmpty},
            error.map {$0 == nil}
        )
            .map {$0 && $1}
            .asDriver(onErrorJustReturn: false)
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        let errorDriver = error.asDriver(onErrorJustReturn: nil)
            
        errorDriver
            .map { error -> String? in
                if error == nil {return nil}
                return L10n.wrongOrderOrSeedPhrasePleaseCheckItAndTryAgain
            }
            .drive(errorLabel.rx.text)
            .disposed(by: disposeBag)
        
        errorDriver
            .map {$0 == nil}
            .drive(retryButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        errorDriver
            .map {$0 == nil}
            .drive(descriptionLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        errorDriver
            .map {$0 != nil}
            .drive(tabBar.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    @objc func buttonNextDidTouch() {
        textView.wrapPhrase(addingPlaceholderAttachment: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.handlePhrases()
        }
    }
    
    @objc func buttonPasteDidTouch() {
        textView.paste(nil)
    }
    
    @objc func resetAndTryAgainButtonDidTouch() {
        textView.clear()
        textView.becomeFirstResponder()
    }
    
    private func handlePhrases()
    {
        hideKeyboard()
        do {
            let phrases = textView.getPhrases()
            _ = try Mnemonic(phrase: phrases.filter {!$0.isEmpty})
            dismiss(animated: true) {
                self.restoreWalletViewModel.navigationSubject.onNext(.welcomeBack(phrases: phrases))
            }
        } catch {
            self.error.accept(error)
        }
    }
}

extension EnterPhrasesVC: WLPhrasesTextViewDelegate {
    func wlPhrasesTextViewDidBeginEditing(_ textView: WLPhrasesTextView) {
        self.error.accept(nil)
    }
}
