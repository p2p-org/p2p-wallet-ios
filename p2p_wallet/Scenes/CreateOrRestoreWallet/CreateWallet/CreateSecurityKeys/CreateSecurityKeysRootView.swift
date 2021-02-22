//
//  CreateSecurityKeysRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import TagListView
import RxSwift

class CreateSecurityKeysRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: CreateSecurityKeysViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    let backButton: UIView
    lazy var phrasesListViews = createTagListView()
    lazy var savedCheckBox = BECheckbox(width: 20, height: 20, cornerRadius: 6)
    
    // MARK: - Initializers
    init(viewModel: CreateSecurityKeysViewModel, backButton: UIView) {
        self.viewModel = viewModel
        self.backButton = backButton
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        layout()
        bind()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
    }
    
    // MARK: - Layout
    private func layout() {
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
                backButton,
                UIImageView(width: 36, height: 36, image: .regenerateButton, tintColor: .a3a5ba)
            ]),
            BEStackViewSpacing(30),
            UILabel(text: L10n.securityKeys.uppercaseFirst, textSize: 27, weight: .bold),
            BEStackViewSpacing(15),
            UILabel(text: L10n.WriteDownOrDuplicateTheseWordsInTheCorrectOrderAndKeepThemInASafePlace.copyThemManuallyOrBackupToICloud, textColor: .textSecondary, numberOfLines: 0),
            BEStackViewSpacing(30),
            UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
                phrasesListViews
                    .padding(.init(top: 10, left: 10, bottom: 16, right: 10), cornerRadius: 12),
                UIView.separator(height: 1, color: .separator),
                UILabel(text: L10n.copyToClipboard, weight: .medium, textColor: .textSecondary, textAlignment: .center)
                    .padding(.init(all: 16))
            ])
                .padding(.zero, backgroundColor: .f6f6f8, cornerRadius: 12),
            BEStackViewSpacing(27),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill, arrangedSubviews: [
                savedCheckBox,
                UILabel(text: L10n.iHaveSavedTheseWordsInASafePlace, weight: .medium)
            ]),
            BEStackViewSpacing(27),
            WLButton.stepButton(type: .black, label: " \(L10n.saveToICloud)"),
            BEStackViewSpacing(16),
            WLButton.stepButton(type: .blue, label: L10n.next)
        ])
    }
    
    private func bind() {
        viewModel.phrasesSubject.subscribe(onNext: { phrases in
            self.phrasesListViews.removeAllTags()
            self.phrasesListViews.addTags(phrases)
            self.layoutIfNeeded()
        })
            .disposed(by: disposeBag)
    }
    
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
