//
//  BackupManuallyVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Foundation
import Action

protocol BackupManuallyVCDelegate: AnyObject {
    func backupManuallyVCDidBackup(_ vc: BackupManuallyVC)
}

class BackupManuallyVC: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    let phrases: [String]
    weak var delegate: BackupManuallyVCDelegate?
    lazy var rootView: ScrollableVStackRootView = {
        let rootView = ScrollableVStackRootView(forAutoLayout: ())
        rootView.scrollView.contentInset = .init(only: .top, inset: 20)
        rootView.stackView.spacing = 20
        rootView.stackView.addArrangedSubviews([
            phrasesListView
        ])
        return rootView
    }()
    
    lazy var phrasesListView: WLPhrasesListView = {
        let listView = WLPhrasesListView(forAutoLayout: ())
        listView.copyToClipboardAction = CocoaAction { [weak self] in
            self?.buttonCopyToClipboardDidTouch()
            return .just(())
        }
        return listView
    }()
    
    lazy var continueButton = WLButton.stepButton(type: .blue, label: L10n.continue)
        .onTap(self, action: #selector(continueButtonDidTouch))
    
    init(accountStorage: SolanaSDKAccountStorage) {
        self.phrases = accountStorage.account?.phrase ?? []
    }
    
    override func setUp() {
        super.setUp()
        // header view
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.securityKey.uppercaseFirst, textSize: 21, weight: .semibold),
                UILabel(text: L10n.done, textSize: 17, textColor: .h5887ff)
                    .onTap(self, action: #selector(back))
            ])
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            UIView.defaultSeparator(),
            rootView
                .padding(.init(x: 20, y: 0))
        ])
        
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(only: .top, inset: 20))
        
        view.addSubview(continueButton)
        continueButton.autoPinEdgesToSuperviewSafeArea(with: .init(x: 20, y: 30), excludingEdge: .top)
        
        // phrase
        phrasesListView.setUp(phrases: phrases)
    }
    
    // MARK: - Actions
    func buttonCopyToClipboardDidTouch() {
        UIApplication.shared.copyToClipboard(phrases.joined(separator: " "))
    }
    
    @objc func continueButtonDidTouch() {
        let vc = BackupPasteSeedPhrasesVC(handler: self)
        show(vc, sender: nil)
    }
}

extension BackupManuallyVC: PhrasesCreationHandler {
    func handlePhrases(_ phrases: [String]) {
        if phrases == self.phrases {
            dismiss(animated: true) { [weak self] in
                guard let `self` = self else {return}
                self.delegate?.backupManuallyVCDidBackup(self)
            }
        } else {
            self.showErrorView(title: L10n.error, description: L10n.thePhrasesYouHasEnteredIsNotCorrect)
        }
    }
}
