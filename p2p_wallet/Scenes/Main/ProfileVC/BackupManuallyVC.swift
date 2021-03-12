//
//  BackupManuallyVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Foundation
import Action

class BackupManuallyVC: WLIndicatorModalVC {
    
    let phrases: [String]
    lazy var rootView = ScrollableVStackRootView(forAutoLayout: ())
    
    lazy var phrasesListView: WLPhrasesListView = {
        let listView = WLPhrasesListView(forAutoLayout: ())
        listView.copyToClipboardAction = CocoaAction {
            self.buttonCopyToClipboardDidTouch()
            return .just(())
        }
        return listView
    }()
    
    init(accountStorage: SolanaSDKAccountStorage) {
        self.phrases = accountStorage.account?.phrase ?? []
    }
    
    override func setUp() {
        super.setUp()
        rootView.scrollView.contentInset = .init(only: .top, inset: 20)
        
        // header view
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UIStackView(axis: .horizontal, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.securityKey.uppercaseFirst, textSize: 21, weight: .semibold),
                UILabel(text: L10n.done, textSize: 17, textColor: .h5887ff)
                    .onTap(self, action: #selector(back))
            ])
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            UIView.separator(height: 1, color: .separator),
            rootView
                .padding(.init(x: 20, y: 0))
        ])
        
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(only: .top, inset: 20))
        
        rootView.stackView.spacing = 20
        rootView.stackView.addArrangedSubviews([
            phrasesListView
        ])
        
        phrasesListView.setUp(phrases: phrases)
    }
    
    // MARK: - Actions
    func buttonCopyToClipboardDidTouch() {
        UIApplication.shared.copyToClipboard(phrases.joined(separator: " "))
    }
}
