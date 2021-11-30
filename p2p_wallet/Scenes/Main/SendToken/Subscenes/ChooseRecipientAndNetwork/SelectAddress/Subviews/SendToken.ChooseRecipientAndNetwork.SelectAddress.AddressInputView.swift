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
            textField.becomeFirstResponder()
        }
        
        private func bind() {
            textField.rx.text
                .map {$0 == nil || $0?.isEmpty == true}
                .asDriver(onErrorJustReturn: true)
                .drive(clearButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            textField.rx.text
                .subscribe(onNext: {[weak self] address in
                    self?.viewModel.userDidEnterAddress(address)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func clearButtonDidTouch() {
            textField.text = nil
            textField.sendActions(for: .editingChanged)
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
