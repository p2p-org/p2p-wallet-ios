//
//  WLPhrasesListView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/03/2021.
//

import Foundation
import TagListView
import Action

class WLPhrasesListView: BEView {
    private lazy var descriptionLabel = UILabel(text: L10n.WriteDownOrDuplicateTheseWordsInTheCorrectOrderAndKeepThemInASafePlace.copyThemManuallyOrBackupToICloud, textColor: .textSecondary, numberOfLines: 0)
    lazy var tagListView: TagListView = {
        let tagListView = TagListView(forAutoLayout: ())
        tagListView.tagBackgroundColor = .tagBackground
        tagListView.textFont = .systemFont(ofSize: 15)
        tagListView.textColor = .textBlack
        tagListView.marginX = 7
        tagListView.marginY = 10
        tagListView.paddingX = 12
        tagListView.paddingY = 12
        tagListView.borderWidth = 1
        tagListView.borderColor = .tagBorder
        tagListView.cornerRadius = 8
        return tagListView
    }()
    lazy var copyToClipboardButton = UILabel(text: L10n.copyToClipboard, weight: .medium, textColor: .textSecondary.onDarkMode(.white), textAlignment: .center)
        .padding(.init(all: 16))
        .onTap(self, action: #selector(copyToClipboard))
    
    var copyToClipboardAction: CocoaAction?
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
            descriptionLabel,
            BEStackViewSpacing(30),
            UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
                tagListView
                    .padding(.init(top: 10, left: 10, bottom: 16, right: 10), cornerRadius: 12),
                UIView.defaultSeparator(),
                copyToClipboardButton
            ])
                .padding(.zero, backgroundColor: .f6f6f8.onDarkMode(.h1b1b1b), cornerRadius: 12)
        ])
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    @objc func copyToClipboard() {
        copyToClipboardAction?.execute()
    }
    
    func setUp(phrases: [String]) {
        tagListView.removeAllTags()
        for (index, phrase) in phrases.enumerated() {
            tagListView.addTag("\(index + 1). \(phrase)")
            tagListView.tagViews[index].setAttributedTitle(
                NSMutableAttributedString()
                    .text("\(index + 1). ", color: .a3a5ba.onDarkMode(.h8d8d8d))
                    .text(phrase),
                for: .normal
            )
                
        }
        setNeedsLayout()
    }
    
    func setUp(description: String) {
        descriptionLabel.text = description
    }
}
