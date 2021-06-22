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
import Action

class CreateSecurityKeysRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: CreateSecurityKeysViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    let backButton: UIView
    lazy var regenerateButton = UIImageView(width: 36, height: 36, image: .regenerateButton, tintColor: .iconSecondary)
        .onTap(viewModel, action: #selector(CreateSecurityKeysViewModel.createPhrases))
    lazy var phrasesListViews: WLPhrasesListView = {
        let listView = WLPhrasesListView(forAutoLayout: ())
        listView.copyToClipboardAction = CocoaAction { [weak self] in
            self?.viewModel.copyToClipboard()
            return .just(())
        }
        return listView
    }()
    lazy var savedCheckBox: BECheckbox = {
        let checkbox = BECheckbox(width: 20, height: 20, cornerRadius: 6)
        checkbox.layer.borderColor = UIColor.a3a5ba.cgColor
        return checkbox
    }()
    
    lazy var saveToICloudButton: WLButton = {
        let button = WLButton.stepButton(type: .black, label: nil)
        
        let attrString = NSMutableAttributedString()
            .text("  ", size: 25, color: button.currentTitleColor)
            .text(L10n.backupToICloud, size: 15, weight: .medium, color: button.currentTitleColor, baselineOffset: (25-15)/4)
        
        button.setAttributedTitle(attrString, for: .normal)
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
            UILabel(text: L10n.securityKey.uppercaseFirst, textSize: 27, weight: .bold),
            BEStackViewSpacing(15),
            phrasesListViews,
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
    }
    
    private func bind() {
        viewModel.phrasesSubject.subscribe(onNext: { phrases in
            self.phrasesListViews.setUp(phrases: phrases)
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
}
