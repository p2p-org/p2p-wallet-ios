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
    lazy var savedCheckBox = BECheckbox(width: 20, height: 20, cornerRadius: 6)
    
    lazy var saveToICloudButton = WLButton.stepButton(type: .black, label: " \(L10n.saveToICloud)")
        .onTap(viewModel, action: #selector(CreateSecurityKeysViewModel.saveToICloud))
    lazy var continueButton = WLButton.stepButton(type: .blue, label: L10n.next)
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
                UILabel(text: L10n.iHaveSavedTheseWordsInASafePlace, weight: .medium)
            ]),
            BEStackViewSpacing(27),
            saveToICloudButton,
            BEStackViewSpacing(16),
            continueButton
        ])
        
        continueButton.isEnabled = false
    }
    
    private func bind() {
        viewModel.phrasesSubject.subscribe(onNext: { phrases in
            self.phrasesListViews.removeAllTags()
            self.phrasesListViews.addTags(phrases)
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
