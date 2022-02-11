//
//  CreateSecurityKeys.RootView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.11.21.
//

import UIKit
import TagListView
import RxSwift
import RxCocoa
import Action

extension CreateSecurityKeys {
    class RootView: ScrollableVStackRootView {
        // MARK: - Dependencies
        private let viewModel: CreateSecurityKeysViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType

        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private let navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.titleLabel.text = L10n.yourSecurityKey
            return navigationBar
        }()
        
        private let saveToICloudButton: WLStepButton = WLStepButton.main(image: .appleLogo, text: L10n.backupToICloud)
        
        private let verifyManualButton: WLStepButton = WLStepButton.sub(text: L10n.verifyManually)
        
        private let keysView: KeysView = KeysView()
        private let keysViewActions: KeysViewActions = KeysViewActions()
        private let agreeTermsAndConditions = AgreeTermsAndConditionsView()
        
        // MARK: - Initializers
        init(viewModel: CreateSecurityKeysViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        override func commonInit() {
            super.commonInit()

            agreeTermsAndConditions.didTouchHyperLink = { [weak viewModel] in
                viewModel?.termsAndConditions()
            }
            layout()
            bind()
        }
        
        // MARK: - Methods
        // MARK: - Layout
        private func layout() {
            // navigation bar
            addSubview(navigationBar)
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)
            
            // content
            scrollView.contentInset.top = 56
            scrollView.contentInset.bottom = 120
            stackView.addArrangedSubviews {
                keysView
                keysViewActions
                BEStackViewSpacing(10)
                agreeTermsAndConditions
            }
            
            // bottom button
            let bottomStack = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
                saveToICloudButton
                verifyManualButton
            }
            bottomStack.backgroundColor = .background
            addSubview(bottomStack)
            bottomStack.autoPinEdgesToSuperviewSafeArea(with: .init(top: 0, left: 18, bottom: 20, right: 18), excludingEdge: .top)
        }
        
        func bind() {
            viewModel.phrasesDriver
                .drive(keysView.rx.keys)
                .disposed(by: disposeBag)
            
            keysViewActions.rx.onCopy
                .bind(onNext: {[weak self] in self?.viewModel.copyToClipboard()})
                .disposed(by: disposeBag)
            keysViewActions.rx.onRefresh
                .bind(onNext: {[weak self] in self?.viewModel.renewPhrases()})
                .disposed(by: disposeBag)
            keysViewActions.rx.onSave
                .bind(onNext: {[weak self] in self?.saveToPhoto()})
                .disposed(by: disposeBag)
    
            verifyManualButton.onTap(self, action: #selector(verifyPhrase))
            saveToICloudButton.onTap(self, action: #selector(saveToICloud))
            navigationBar.backButton.onTap(self, action: #selector(back))
        }
        
        // MARK: - Actions
        @objc func saveToICloud() {
            viewModel.saveToICloud()
        }
    
        @objc func verifyPhrase() {
            viewModel.verifyPhrase()
        }
    
        @objc func back() {
            viewModel.back()
        }
        
        func saveToPhoto() {
            analyticsManager.log(event: .createWalletSaveSeedToPhotosClick)
            viewModel.saveKeysImage(keysView.asImage())
        }
    }
}
