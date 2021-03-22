//
//  EnterPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2020.
//

import Foundation
import UITextView_Placeholder
import SubviewAttachingTextView

class EnterPhrasesVC: BaseVStackVC {
    override var padding: UIEdgeInsets {.init(all: 20)}
    
    lazy var textView = WLPhrasesTextView()
    
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
    
    let restoreWalletViewModel: RestoreWalletViewModel
    init(restoreWalletViewModel: RestoreWalletViewModel) {
        self.restoreWalletViewModel = restoreWalletViewModel
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        title = L10n.enterSecurityKeys
        stackView.addArrangedSubview(
            textView
                .padding(.init(all: 10), backgroundColor: .lightGrayBackground, cornerRadius: 16)
                .border(width: 1, color: .a3a5ba)
        )
        
        // tabBar
        view.addSubview(tabBar)
        tabBar.autoPinEdge(toSuperviewEdge: .leading)
        tabBar.autoPinEdge(toSuperviewEdge: .trailing)
        tabBar.autoPinBottomToSuperViewAvoidKeyboard()
        
        textView.becomeFirstResponder()
    }
    
    override func bind() {
        super.bind()
        textView.rx.text
            .map {_ in !self.textView.getPhrases().isEmpty}
            .asDriver(onErrorJustReturn: false)
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    @objc func buttonNextDidTouch() {
        textView.wrapPhrase()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.handlePhrases()
        }
    }
    
    @objc func buttonPasteDidTouch() {
        textView.paste(nil)
    }
    
    private func handlePhrases()
    {
        do {
            let phrases = textView.getPhrases()
            _ = try Mnemonic(phrase: phrases.filter {!$0.isEmpty})
            dismiss(animated: true) {
                self.restoreWalletViewModel.navigationSubject.onNext(.welcomeBack(phrases: phrases))
            }
        } catch {
            showError(error)
        }
    }
}
