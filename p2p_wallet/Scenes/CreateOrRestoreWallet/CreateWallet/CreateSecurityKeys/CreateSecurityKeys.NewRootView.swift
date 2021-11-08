//
//  CreateSecurityKeys.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import UIKit
import TagListView
import RxSwift
import RxCocoa
import Action

extension CreateSecurityKeys {
    class NewRootView: ScrollableVStackRootView {
        // MARK: - Dependencies
        @Injected private var viewModel: CreateSecurityKeysViewModelType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private let navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton
                .onTap(self, action: #selector(back))
            navigationBar.titleLabel.text = L10n.yourSecurityKey
            return navigationBar
        }()
        
        private let saveToICloudButton: WLButton = {
            let button = WLButton.stepButton(type: .black, label: nil)
            
            let attrString = NSMutableAttributedString()
                .text("  ", size: 25, color: button.currentTitleColor)
                .text(L10n.backupToICloud, size: 15, weight: .medium, color: button.currentTitleColor, baselineOffset: (25 - 15) / 4)
            
            button.setAttributedTitle(attrString, for: .normal)
            return button
        }()
        
        private let keysView: KeysView = KeysView(footer: nil)
        
        // MARK: - Initializers
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
    
        // MARK: - Methods
        // MARK: - Layout
        private func layout() {
            addSubview(navigationBar)
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)
    
            scrollView.contentInset.top = 56
            stackView.addArrangedSubview(keysView)
            
            
            
            let bottomStack = UIStackView(axis: .vertical) {
                saveToICloudButton
            }
            addSubview(bottomStack)
            bottomStack.autoPinEdgesToSuperviewSafeArea(with: .init(x: 18, y: 20), excludingEdge: .top)
        }
        
        func bind() {
            viewModel.phrasesDriver.drive(keysView.rx.keys).disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc func createPhrases() {
            viewModel.createPhrases()
        }
        
        @objc func toggleCheckbox() {
            viewModel.toggleCheckbox()
        }
        
        @objc func saveToICloud() {
            viewModel.saveToICloud()
        }
        
        @objc func goNext() {
            viewModel.next()
        }

        @objc func back() {
            viewModel.back()
        }
    }
}
