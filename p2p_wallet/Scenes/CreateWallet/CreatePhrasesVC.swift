//
//  CreatePhrasesVC.swift
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
    
    lazy var buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
    
    init(phrases: [String] = []) {
        self.phrases.accept(phrases)
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        title = L10n.securityKeys.uppercaseFirst
    }
    
    // MARK: - Helpers
    func createTagListView() -> TagListView {
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
}

class CreatePhrasesVC: PhrasesVC {
    lazy var phrasesListViews = createTagListView()
    lazy var copyToClipboardButton =
        UIView.copyToClipboardButton()
            .onTap(self, action: #selector(buttonCopyToClipboardDidTouch))
    lazy var savedCheckBox = BECheckbox(width: 20, height: 20, cornerRadius: 6)
    lazy var saveToICloudButton = WLButton.stepButton(type: .blue, label: L10n.saveToICloud.uppercaseFirst)
        .onTap(self, action: #selector(buttonSaveToKeychainDidTouch))
    
    lazy var regenerateButton: UIBarButtonItem = {
        let image = UIImage.regenerateButton.withRenderingMode(.alwaysOriginal)
        let button = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
        button.target = self
        button.action = #selector(buttonRegenerateDidTouch)
        return button
    }()
    
    lazy var continueButton = WLButton.stepButton(type: .blue, label: L10n.continue)
        .onTap(self, action: #selector(buttonContinueDidTouch))
    
    let accountStorage: KeychainAccountStorage
    init(accountStorage: KeychainAccountStorage) {
        self.accountStorage = accountStorage
    }
    
    override func setUp() {
        super.setUp()
        navigationItem.rightBarButtonItem = regenerateButton
        
        stackView.alignment = .fill
        stackView.spacing = 20
        
        stackView.addArrangedSubviews([
            UIStackView(axis: .vertical, spacing: 22, alignment: .fill, distribution: .fill, arrangedSubviews: [
                phrasesListViews.padding(UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)),
                copyToClipboardButton
                    .centeredHorizontallyView
            ])
                .padding(.init(x: 0, y: 20), backgroundColor: .lightGrayBackground, cornerRadius: 16)
                .padding(.init(x: 20, y: 0)),
            
            UILabel(text: L10n.orSavingIntoKeychain, textColor: .textSecondary, textAlignment: .center),
            
            saveToICloudButton
                .padding(.init(x: 20, y: 0)),
            
            UILabel(
                text: L10n.weVeCreatedSomeSecurityKeywordsForYou.uppercaseFirst + "\n" + L10n.warningTheSeedPhraseWillNotBeShownAgainCopyItDownOrSaveInYourPasswordManagerToRecoverThisWalletInTheFuture,
                textSize: 15,
                weight: .medium,
                textColor: .textSecondary,
                numberOfLines: 0,
                textAlignment: .center
            )
                .padding(.init(x: 20, y: 0))
        ])
        
        scrollView.constraintToSuperviewWithAttribute(.bottom)?.isActive = false
        
        view.addSubview(buttonStackView)
        buttonStackView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 0, left: 20, bottom: 16, right: 20), excludingEdge: .top)
        buttonStackView.autoPinEdge(.top, to: .bottom, of: scrollView, withOffset: 10)
        
        buttonStackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill, arrangedSubviews: [
                savedCheckBox,
                UILabel(text: L10n.iHaveSavedTheseWordsInASafePlace, weight: .medium)
            ])
                .centeredHorizontallyView,
            continueButton
        ])
        
        if phrases.value.isEmpty {
            createAccount()
        }
    }
    
    override func bind() {
        super.bind()
        phrases.subscribe(onNext: { phrases in
            self.phrasesListViews.removeAllTags()
            self.phrasesListViews.addTags(phrases)
            self.view.layoutIfNeeded()
        })
            .disposed(by: disposeBag)
        
        continueButton.isEnabled = false
        savedCheckBox.rx.tap
            .map {_ in self.savedCheckBox.isSelected}
            .asDriver(onErrorJustReturn: false)
            .drive(continueButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    func createAccount() {
        let mnemonic = Mnemonic()
        self.phrases.accept(mnemonic.phrase)
    }
    
    // MARK: - Actions
    @objc func buttonCopyToClipboardDidTouch() {
        UIApplication.shared.copyToClipboard(phrases.value.joined(separator: " "))
    }
    
    @objc func buttonSaveToKeychainDidTouch() {
        accountStorage.saveICloud(phrases: phrases.value.joined(separator: " "))
        UIApplication.shared.showDone(L10n.savedToICloud)
    }
    
    @objc func buttonRegenerateDidTouch() {
        createAccount()
        // clear
        savedCheckBox.isSelected = false
        continueButton.isEnabled = false
        accountStorage.clear()
    }
    
    @objc func buttonContinueDidTouch() {
        UIApplication.shared.showIndetermineHudWithMessage(L10n.creatingAnAccount.uppercaseFirst)
        DispatchQueue.global().async {
            do {
                let account = try SolanaSDK.Account(phrase: self.phrases.value, network: Defaults.network)
                try self.accountStorage.save(account)
                DispatchQueue.main.async {
                    UIApplication.shared.hideHud()
                    let vc = DependencyContainer.shared.makeSSPinCodeVC()
                    self.show(vc, sender: nil)
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
