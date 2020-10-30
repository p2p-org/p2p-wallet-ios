//
//  PhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import TagListView
import RxCocoa

class PhrasesVC: BaseVStackVC {
    override var padding: UIEdgeInsets {
        var padding = super.padding
        padding.top += 16
        return padding
    }
    let phrases = BehaviorRelay<[String]>(value: [])
    
    lazy var topPhrasesListViews = createTagListView()
    
    lazy var label = UILabel(
        text: L10n.weVeCreatedSomeSecurityKeywordsForYou.uppercaseFirst + "\n" + L10n.warningTheSeedPhraseWillNotBeShownAgainCopyItDownOrSaveInYourPasswordManagerToRecoverThisWalletInTheFuture,
        textSize: 15,
        weight: .medium,
        textColor: UIColor.textBlack.withAlphaComponent(0.5),
        numberOfLines: 0,
        textAlignment: .center
    )
    
    lazy var bottomPhrasesListView = createTagListView()
    
    lazy var saveToKeychainButton = WLButton.stepButton(type: .main, label: L10n.saveToKeychain.uppercaseFirst)
        .onTap(self, action: #selector(buttonSaveToKeychainDidTouch))
    
    init(phrases: [String] = []) {
        self.phrases.accept(phrases)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        title = L10n.securityKeys.uppercaseFirst
        
        stackView.alignment = .center
        
        let firstKeysBackgroundView: UIView = {
            let view = UIView(height: 176, backgroundColor: .lightGrayBackground, cornerRadius: 16)
            view.addSubview(topPhrasesListViews)
            topPhrasesListViews.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
            topPhrasesListViews.autoPinEdge(toSuperviewEdge: .leading, withInset: 40)
            topPhrasesListViews.autoPinEdge(toSuperviewEdge: .trailing, withInset: 40)
            return view
        }()
        
        stackView.addArrangedSubview(firstKeysBackgroundView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(bottomPhrasesListView)
        
        stackView.setCustomSpacing(30, after: firstKeysBackgroundView)
        stackView.setCustomSpacing(40, after: label)
        
        firstKeysBackgroundView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
            .isActive = true
        label.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
                .isActive = true
        bottomPhrasesListView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -120).isActive = true
        
        view.addSubview(saveToKeychainButton)
        saveToKeychainButton.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 0, left: 20, bottom: 16, right: 20), excludingEdge: .top)
        
        if phrases.value.isEmpty {
            createAccount()
        }
    }
    
    override func bind() {
        super.bind()
        phrases.subscribe(onNext: { phrases in
            self.label.isHidden = phrases.isEmpty
            self.topPhrasesListViews.removeAllTags()
            let phrases = phrases.enumerated().map {"\($0.offset) \($0.element)"}.shuffled()
            self.topPhrasesListViews.addTags(Array(phrases.prefix(6)))
            self.bottomPhrasesListView.removeAllTags()
            if phrases.count > 6 {self.bottomPhrasesListView.addTags(Array(phrases[6..<phrases.count]))}
        })
            .disposed(by: disposeBag)
    }
    
    func createAccount() {
        let mnemonic = Mnemonic()
        self.phrases.accept(mnemonic.phrase)
    }
    
    // MARK: - Helpers
    private func createTagListView() -> TagListView {
        let tagListView = TagListView(forAutoLayout: ())
        tagListView.tagBackgroundColor = .textWhite
        tagListView.textFont = .systemFont(ofSize: 18)
        tagListView.textColor = .textBlack
        tagListView.marginX = 5
        tagListView.marginY = 5
        tagListView.paddingX = 10
        tagListView.paddingY = 6
        tagListView.borderWidth = 1
        tagListView.borderColor = .textBlack
        tagListView.cornerRadius = 5
        return tagListView
    }
    
    // MARK: - Actions
    @objc func buttonSaveToKeychainDidTouch() {
        UIApplication.shared.showIndetermineHudWithMessage(L10n.creatingAnAccount.uppercaseFirst)
        DispatchQueue.global().async {
            do {
                let account = try SolanaSDK.Account(phrase: self.phrases.value)
                try KeychainStorage.shared.save(account)
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    self.show(CreateWalletCompletedVC(), sender: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    self.showError(error, additionalMessage: L10n.tapRefreshButtonToRetry)
                }
            }
        }
    }
}
