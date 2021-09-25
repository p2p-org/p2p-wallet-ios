//
//  CreateSecurityKeys.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import TagListView
import RxSwift
import Action

extension CreateSecurityKeys {
    class RootView: ScrollableVStackRootView {
        // MARK: - Dependencies
        @Injected private var viewModel: CreateSecurityKeysViewModelType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private let backButton: UIView
        private lazy var regenerateButton = UIImageView(width: 36, height: 36, image: .regenerateButton, tintColor: .iconSecondary)
            .onTap(self, action: #selector(createPhrases))
        private lazy var phrasesListViews: WLPhrasesListView = {
            let listView = WLPhrasesListView(forAutoLayout: ())
            listView.copyToClipboardAction = CocoaAction { [weak self] in
                self?.viewModel.copyToClipboard()
                return .just(())
            }
            return listView
        }()
        private lazy var savedCheckBox: BECheckbox = {
            let checkbox = BECheckbox(width: 20, height: 20, cornerRadius: 6)
            checkbox.layer.borderColor = UIColor.a3a5ba.cgColor
            return checkbox
        }()
        
        private lazy var saveToICloudButton: WLButton = {
            let button = WLButton.stepButton(type: .black, label: nil)
            
            let attrString = NSMutableAttributedString()
                .text("  ", size: 25, color: button.currentTitleColor)
                .text(L10n.backupToICloud, size: 15, weight: .medium, color: button.currentTitleColor, baselineOffset: (25-15)/4)
            
            button.setAttributedTitle(attrString, for: .normal)
            return button
        }()
            
        private lazy var continueButton = WLButton.stepButton(type: .blue, label: L10n.next.uppercaseFirst)
            .onTap(self, action: #selector(goNext))
        
        // MARK: - Initializers
        init(backButton: UIView) {
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
                    .onTap(self, action: #selector(saveToICloud)),
                BEStackViewSpacing(16),
                continueButton,
                BEStackViewSpacing(30),
                UIView()
            ])
            
            continueButton.isEnabled = false
        }
        
        private func bind() {
            viewModel.phrasesDriver
                .drive(onNext: {[weak self] phrases in
                    self?.phrasesListViews.setUp(phrases: phrases)
                })
                .disposed(by: disposeBag)
            
            viewModel.isCheckboxSelectedDriver
                .drive(savedCheckBox.rx.isSelected)
                .disposed(by: disposeBag)
            
            savedCheckBox.rx.tap
                .subscribe(onNext: {[weak self] in
                    self?.viewModel.toggleCheckbox(selected: self?.savedCheckBox.isSelected ?? false)
                })
                .disposed(by: disposeBag)
            
            viewModel.isCheckboxSelectedDriver
                .drive(continueButton.rx.isEnabled)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc func createPhrases() {
            viewModel.createPhrases()
        }
        
        @objc func saveToICloud() {
            viewModel.saveToICloud()
        }
        
        @objc func goNext() {
            viewModel.next()
        }
    }
}
