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
    class NewRootView: ScrollableVStackRootView {
        // MARK: - Dependencies
        @Injected private var viewModel: CreateSecurityKeysViewModelType
        
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
        private let keysViewAction: KeysViewActions = KeysViewActions()
        
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
            scrollView.contentInset.bottom = 120
            stackView.addArrangedSubview(keysView)
            stackView.addArrangedSubview(keysViewAction)
            
            let bottomStack = UIStackView(axis: .vertical, alignment: .fill, distribution: .fill) {
                saveToICloudButton
                verifyManualButton.padding(UIEdgeInsets(only: .bottom, inset: 20))
            }
            bottomStack.backgroundColor = .background
            addSubview(bottomStack)
            bottomStack.autoPinEdgesToSuperviewSafeArea(with: .init(x: 18, y: 0), excludingEdge: .top)
        }
        
        func bind() {
            viewModel.phrasesDriver
                .drive(keysView.rx.keys)
                .disposed(by: disposeBag)
            
            keysViewAction.rx.onCopy
                .bind(onNext: {[weak self] in self?.viewModel.copyToClipboard()})
                .disposed(by: disposeBag)
            keysViewAction.rx.onRefresh
                .bind(onNext: {[weak self] in self?.viewModel.createPhrases()})
                .disposed(by: disposeBag)
            keysViewAction.rx.onSave
                .bind(onNext: {[weak self] in self?.saveToPhoto()})
                .disposed(by: disposeBag)
            
            saveToICloudButton.onTap(self, action: #selector(saveToICloud))
            navigationBar.backButton.onTap(self, action: #selector(back))
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
        
        func saveToPhoto() {
            UIImageWriteToSavedPhotosAlbum(keysView.asImage(), self, #selector(saveImageCallback), nil)
        }
        
        @objc private func saveImageCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            if let error = error {
                showErrorView(error: error)
            } else {
                UIApplication.shared.showToast(message: "✅ \(L10n.savedToPhotoLibrary)")
            }
        }
    }
}
