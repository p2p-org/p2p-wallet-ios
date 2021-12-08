//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.AddressInputView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation
import UIKit
import RxSwift

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class AddressInputView: UIStackView {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        lazy var textField = createTextField()
        lazy var clearButton = UIImageView(width: 17, height: 17, image: .crossIcon)
            .onTap(self, action: #selector(clearButtonDidTouch))
        
        // MARK: - Initializers
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            self.set(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)
            self.addArrangedSubviews {
                UIImageView(width: 24, height: 24, image: .buttonSearch, tintColor: .a3a5ba)
                    .padding(.init(all: 10), backgroundColor: .f6f6f8, cornerRadius: 16)
                textField
                clearButton
            }
            bind()
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Methods
        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else {return}
                self.textField.becomeFirstResponder()
                #if DEBUG
                var didTake = false
                self.viewModel.walletDriver
                    .drive(onNext: { [weak self] in
                        guard !didTake else {return}
                        didTake = true
                        if $0?.token.isRenBTC == true {
                            self?.viewModel.search("tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt")
                        } else {
                            self?.viewModel.search("chu")
                        }
                    })
                    .disposed(by: self.disposeBag)
                #endif
            }
        }
        
        private func bind() {
            textField.rx.text
                .distinctUntilChanged()
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .subscribe(onNext: {[weak self] address in
                    self?.viewModel.search(address)
                })
                .disposed(by: disposeBag)
            
            viewModel.searchTextDriver
                .distinctUntilChanged()
                .drive(textField.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.searchTextDriver
                .distinctUntilChanged()
                .map {$0 == nil || $0?.isEmpty == true}
                .asDriver(onErrorJustReturn: true)
                .drive(clearButton.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc func clearButtonDidTouch() {
            viewModel.clearSearching()
        }
        
        // MARK: - Helpers
        private func createTextField() -> UITextField {
            let textField = UITextField(
                backgroundColor: .clear,
                font: .systemFont(ofSize: 15, weight: .medium),
                placeholder: nil,
                autocorrectionType: .no,
                autocapitalizationType: UITextAutocapitalizationType.none,
                spellCheckingType: .no
            )
            textField.attributedPlaceholder = NSAttributedString(
                string: L10n.p2PUsernameSOLAddress,
                attributes: [
                    .foregroundColor: UIColor.a3a5ba.onDarkMode(.h5887ff),
                    .font: UIFont.systemFont(ofSize: 15, weight: .medium)
                ]
            )
            return textField
        }
    }
}
