//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.AddressInputView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Combine
import CombineCocoa
import Foundation
import UIKit

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class AddressInputView: UIStackView {
        // MARK: - Dependencies

        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        private var subscriptions = [AnyCancellable]()

        // MARK: - Subviews

        lazy var textField = createTextField()
        lazy var clearButton = UIImageView(width: 17, height: 17, image: .crossIcon)
            .onTap(self, action: #selector(clearButtonDidTouch))

        // MARK: - Initializers

        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            set(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                UIImageView(width: 24, height: 24, image: .buttonSearch, tintColor: .a3a5ba)
                    .padding(.init(all: 10), backgroundColor: .f6f6f8, cornerRadius: 16)
                textField
                clearButton
            }
            bind()

            if viewModel.getCurrentInputState() == .searching {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    #if DEBUG
                        var didTake = false
                        self.viewModel.walletPublisher
                            .sink { [weak self] in
                                guard !didTake else { return }
                                didTake = true
                                if $0?.token.isRenBTC == true {
                                    self?.viewModel.search("tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt")
                                } else {
                                    self?.viewModel.search("bigears")
                                }
                            }
                            .store(in: &self.subscriptions)
                    #endif
                }
            }
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Methods

        private func bind() {
            textField.textPublisher
                .removeDuplicates()
                .debounce(for: 300, scheduler: RunLoop.main)
                .sink { [weak self] address in
                    self?.viewModel.search(address)
                }
                .store(in: &subscriptions)

            viewModel.searchTextPublisher
                .removeDuplicates()
                .assign(to: \.text, on: textField)
                .store(in: &subscriptions)

            viewModel.searchTextPublisher
                .removeDuplicates()
                .map { $0 == nil || $0?.isEmpty == true }
                .assign(to: \.isHidden, on: clearButton)
                .store(in: &subscriptions)
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
                string: L10n.usernameOrAddress,
                attributes: [
                    .foregroundColor: UIColor.a3a5ba.onDarkMode(.h5887ff),
                    .font: UIFont.systemFont(ofSize: 15, weight: .medium),
                ]
            )
            return textField
        }
    }
}
