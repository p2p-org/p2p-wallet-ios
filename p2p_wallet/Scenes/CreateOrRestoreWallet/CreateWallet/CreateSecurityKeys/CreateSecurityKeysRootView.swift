//
//  CreateSecurityKeysRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import TagListView
import RxSwift
import RxBiBinding

class CreateSecurityKeysRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: CreateSecurityKeysViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    let backButton: UIView
    lazy var regenerateButton = UIImageView(width: 36, height: 36, image: .regenerateButton, tintColor: .a3a5ba)
        .onTap(viewModel, action: #selector(CreateSecurityKeysViewModel.createPhrases))
    lazy var phrasesListViews = createTagListView()
    lazy var copyToClipboardButton = UILabel(text: L10n.copyToClipboard, weight: .medium, textColor: .textSecondary, textAlignment: .center)
        .padding(.init(all: 16))
        .onTap(viewModel, action: #selector(CreateSecurityKeysViewModel.copyToClipboard))
    lazy var savedCheckBox: BECheckbox = {
        let checkbox = BECheckbox(width: 20, height: 20, cornerRadius: 6)
        checkbox.layer.borderColor = UIColor.a3a5ba.cgColor
        return checkbox
    }()
    
    lazy var saveToICloudButton: WLButton = {
        let button = WLButton.stepButton(type: .black, label: " \(L10n.saveToICloud)")
        button.titleLabel?.attributedText = NSMutableAttributedString()
            .text(" ", size: 25, color: button.currentTitleColor)
            .text(L10n.saveToICloud, size: 15, weight: .medium, color: button.currentTitleColor)
        return button
    }()
        
    lazy var continueButton = WLButton.stepButton(type: .blue, label: L10n.next.uppercaseFirst)
        .onTap(viewModel, action: #selector(CreateSecurityKeysViewModel.next))
    
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
        let topView = UIStackView(axis: .horizontal, alignment: .center, distribution: .equalSpacing, arrangedSubviews: [
            backButton,
            regenerateButton
        ])
        addSubview(topView)
        topView.autoPinEdgesToSuperviewEdges(with: .init(all: 20), excludingEdge: .bottom)
        
        scrollView.constraintToSuperviewWithAttribute(.top)?.constant = 66
        stackView.addArrangedSubviews([
            UILabel(text: L10n.securityKeys.uppercaseFirst, textSize: 27, weight: .bold),
            BEStackViewSpacing(15),
            UILabel(text: L10n.WriteDownOrDuplicateTheseWordsInTheCorrectOrderAndKeepThemInASafePlace.copyThemManuallyOrBackupToICloud, textColor: .textSecondary, numberOfLines: 0),
            BEStackViewSpacing(30),
            UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
                phrasesListViews
                    .padding(.init(top: 10, left: 10, bottom: 16, right: 10), cornerRadius: 12),
                UIView.separator(height: 1, color: .separator),
                copyToClipboardButton
            ])
                .padding(.zero, backgroundColor: .f6f6f8, cornerRadius: 12),
            BEStackViewSpacing(27),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill, arrangedSubviews: [
                savedCheckBox,
                UILabel(text: L10n.iHaveSavedTheseWordsInASafePlace, weight: .medium, textColor: .textSecondary)
            ]),
            BEStackViewSpacing(27),
            saveToICloudButton
                .onTap(viewModel, action: #selector(CreateSecurityKeysViewModel.saveToICloud)),
            BEStackViewSpacing(16),
            continueButton,
            BEStackViewSpacing(30),
            UIView()
        ])
        
        continueButton.isEnabled = false
        
        scrollView.constraintToSuperviewWithAttribute(.bottom)?.constant = 0
    }
    
    private func bind() {
        viewModel.phrasesSubject.subscribe(onNext: { phrases in
            self.phrasesListViews.removeAllTags()
            for (index, phrase) in phrases.enumerated() {
                self.phrasesListViews.addTag("\(index + 1). \(phrase)")
                self.phrasesListViews.tagViews[index].setAttributedTitle(
                    NSMutableAttributedString()
                        .text("\(index + 1). ", color: .a3a5ba)
                        .text(phrase),
                    for: .normal
                )
                    
            }
            self.layoutIfNeeded()
        })
            .disposed(by: disposeBag)
        
        viewModel.checkBoxIsSelectedInput
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .drive(savedCheckBox.rx.isSelected)
            .disposed(by: disposeBag)
        
        savedCheckBox.rx.tap
            .map {_ in self.savedCheckBox.isSelected}
            .bind(to: viewModel.checkBoxIsSelectedInput)
            .disposed(by: disposeBag)
        
        viewModel.checkBoxIsSelectedInput
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .drive(continueButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    func createTagListView() -> TagListView {
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
    }
}
