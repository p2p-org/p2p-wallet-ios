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
        textColor: .secondary,
        numberOfLines: 0,
        textAlignment: .center
    )
    
    lazy var bottomPhrasesListView = createTagListView()
    
    lazy var buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
    lazy var copyToClipboardButton = WLButton.stepButton(type: .sub, label: L10n.copyToClipboard)
        .onTap(self, action: #selector(buttonCopyToClipboardDidTouch))
    lazy var savedCheckBox = BECheckbox(width: 20, height: 20, cornerRadius: 6)
    lazy var saveToKeychainButton = WLButton.stepButton(type: .main, label: L10n.saveToKeychain.uppercaseFirst)
        .onTap(self, action: #selector(buttonSaveToKeychainDidTouch))
    
    lazy var regenerateButton: UIBarButtonItem = {
        let image = UIImage.regenerateButton.withRenderingMode(.alwaysOriginal)
        let button = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
        button.target = self
        button.action = #selector(buttonRegenerateDidTouch)
        return button
    }()
    
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
        navigationItem.rightBarButtonItem = regenerateButton
        
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
        
        scrollView.constraintToSuperviewWithAttribute(.bottom)?.isActive = false
        
        view.addSubview(buttonStackView)
        buttonStackView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 0, left: 20, bottom: 16, right: 20), excludingEdge: .top)
        buttonStackView.autoPinEdge(.top, to: .bottom, of: scrollView)
        
        let savedConfirmView: UIStackView = {
            let stackView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill)
            let spacer1 = UIView.spacer
            let spacer2 = UIView.spacer
            let label = UILabel(text: L10n.iHaveSavedTheseWordsInASafePlace, weight: .medium)
            label.adjustsFontSizeToFitWidth = true
            stackView.addArrangedSubviews([
                spacer1,
                savedCheckBox,
                label,
                spacer2
            ])
            spacer1.widthAnchor.constraint(equalTo: spacer2.widthAnchor).isActive = true
            return stackView
        }()
        
        buttonStackView.addArrangedSubviews([
            copyToClipboardButton,
            savedConfirmView,
            saveToKeychainButton
        ])
        
        if phrases.value.isEmpty {
            createAccount()
        }
    }
    
    override func bind() {
        super.bind()
        phrases.subscribe(onNext: { phrases in
            self.label.isHidden = phrases.isEmpty
            self.topPhrasesListViews.removeAllTags()
            let phrases = phrases.enumerated().map {"\($0.offset + 1) \($0.element)"}.shuffled()
            self.topPhrasesListViews.addTags(Array(phrases.prefix(6)))
            self.bottomPhrasesListView.removeAllTags()
            if phrases.count > 6 {self.bottomPhrasesListView.addTags(Array(phrases[6..<phrases.count]))}
        })
            .disposed(by: disposeBag)
        
        saveToKeychainButton.isEnabled = false
        savedCheckBox.rx.tap
            .map {_ in self.savedCheckBox.isSelected}
            .asDriver(onErrorJustReturn: false)
            .drive(saveToKeychainButton.rx.isEnabled)
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
    @objc func buttonCopyToClipboardDidTouch() {
        UIPasteboard.general.string = phrases.value.joined(separator: " ")
        UIApplication.shared.showDone(L10n.copiedToClipboard)
    }
    
    @objc func buttonSaveToKeychainDidTouch() {
        UIApplication.shared.showIndetermineHudWithMessage(L10n.creatingAnAccount.uppercaseFirst)
        DispatchQueue.global().async {
            do {
                let account = try SolanaSDK.Account(phrase: self.phrases.value, network: SolanaSDK.network)
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
    
    @objc func buttonRegenerateDidTouch() {
        createAccount()
    }
}
