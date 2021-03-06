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
    lazy var tagListView: TagListView = {
        let tagListView = TagListView(forAutoLayout: ())
        tagListView.tagBackgroundColor = .textWhite
        tagListView.textFont = .systemFont(ofSize: 15)
        tagListView.textColor = .textBlack
        tagListView.marginX = 7
        tagListView.marginY = 10
        tagListView.paddingX = 12
        tagListView.paddingY = 12
        tagListView.borderWidth = 1
        tagListView.borderColor = UIColor.a3a5ba.withAlphaComponent(0.5)
        tagListView.cornerRadius = 8
        return tagListView
    }()
    lazy var copyToClipboardButton = UILabel(text: L10n.copyToClipboard, weight: .medium, textColor: .textSecondary, textAlignment: .center)
        .padding(.init(all: 16))
        .onTap(self, action: #selector(copyToClipboard))
    
    var copyToClipboardAction: CocoaAction?
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UILabel(text: L10n.WriteDownOrDuplicateTheseWordsInTheCorrectOrderAndKeepThemInASafePlace.copyThemManuallyOrBackupToICloud, textColor: .textSecondary, numberOfLines: 0),
            BEStackViewSpacing(30),
            UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
                tagListView
                    .padding(.init(top: 10, left: 10, bottom: 16, right: 10), cornerRadius: 12),
                UIView.separator(height: 1, color: .separator),
                copyToClipboardButton
            ])
                .padding(.zero, backgroundColor: .f6f6f8, cornerRadius: 12)
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
                    .text("\(index + 1). ", color: .a3a5ba)
                    .text(phrase),
                for: .normal
            )
                
        }
        setNeedsLayout()
    }
}
