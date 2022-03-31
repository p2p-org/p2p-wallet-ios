//
//  WLPhrasesListView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/03/2021.
//

import Action
import Foundation
import TagListView

class WLPhrasesListView: BEView {
    private lazy var descriptionLabel = UILabel(
        text: L10n.WriteDownOrDuplicateTheseWordsInTheCorrectOrderAndKeepThemInASafePlace
            .copyThemManuallyOrBackupToICloud,
        textColor: .textSecondary,
        numberOfLines: 0
    )
    lazy var tagListView: TagListView = {
        let tagListView = TagListView(forAutoLayout: ())
        tagListView.tagBackgroundColor = .tagBackground
        tagListView.textFont = .systemFont(ofSize: 15)
        tagListView.textColor = .textBlack
        tagListView.marginX = 6
        tagListView.marginY = 4
        tagListView.paddingX = 12
        tagListView.paddingY = 6
        tagListView.borderWidth = 1
        tagListView.borderColor = .tagBorder
        tagListView.cornerRadius = 8
        return tagListView
    }()

    lazy var copyToClipboardButton = UILabel(
        text: L10n.copyToClipboard,
        weight: .medium,
        textColor: .textSecondary.onDarkMode(.white),
        textAlignment: .center
    )
        .padding(.init(all: 9))
        .onTap(self, action: #selector(copyToClipboard))

    var copyToClipboardAction: CocoaAction?

    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(
            axis: .vertical,
            spacing: 0,
            alignment: .fill,
            distribution: .fill,
            arrangedSubviews: [
                descriptionLabel,
                BEStackViewSpacing(20),
                UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    tagListView
                        .padding(.init(all: 10), cornerRadius: 12),
                    UIView.defaultSeparator(),
                    copyToClipboardButton,
                ])
                    .padding(.zero, backgroundColor: .f6f6f8.onDarkMode(.h1b1b1b), cornerRadius: 12),
            ]
        )
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
