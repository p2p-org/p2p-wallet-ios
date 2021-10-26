//
//  SelectRecipient.AddressView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 22.10.2021.
//

import UIKit
import RxSwift

extension SelectRecipient {
    final class AddressView: UIStackView {
        private let viewModel: SelectRecipientViewModelType
        private let disposeBag = DisposeBag()

        private lazy var addressTextField: UITextField = {
            let textField = UITextField(
                height: 44,
                backgroundColor: .clear,
                placeholder: L10n._0xESNOrP2pUsername,
                autocorrectionType: .none,
                autocapitalizationType: UITextAutocapitalizationType.none,
                spellCheckingType: .no,
                horizontalPadding: 8
            )
            textField.attributedPlaceholder = NSAttributedString(
                string: L10n.walletAddress,
                attributes: [.foregroundColor: UIColor.a3a5ba.onDarkMode(.h5887ff)]
            )
            return textField
        }()

        private let clearAddressButton = UIImageView(width: 24, height: 24, image: .closeFill, tintColor: UIColor.black.withAlphaComponent(0.6))
        private let qrCodeImageView = UIImageView(width: 35, height: 35, image: .scanQr3, tintColor: .a3a5ba)

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        init(viewModel: SelectRecipientViewModelType) {
            self.viewModel = viewModel

            super.init(frame: .zero)

            configureSelf()
            configureSubviews()
            bind()
        }

        private func configureSelf() {
            axis = .horizontal
            spacing = 0
            alignment = .center
            distribution = .fill

            [addressTextField, clearAddressButton, qrCodeImageView].forEach(addArrangedSubview)
        }

        private func configureSubviews() {
            qrCodeImageView.onTap(self, action: #selector(scanQrCode))
            clearAddressButton.onTap(self, action: #selector(clearDestinationAddress))
        }

        private func bind() {
            addressTextField.rx.text
                .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .bind(to: viewModel.recipientSearchSubject)
                .disposed(by: disposeBag)

            viewModel.recipientSearchDriver
                .drive(addressTextField.rx.text)
                .disposed(by: disposeBag)

            let destinationAddressInputEmpty = viewModel.recipientSearchDriver
                .map {$0 == nil || $0!.isEmpty}

            destinationAddressInputEmpty
                .drive(clearAddressButton.rx.isHidden)
                .disposed(by: disposeBag)

            let destinationAddressInputNotEmpty = destinationAddressInputEmpty
                .map {!$0}

            destinationAddressInputNotEmpty
                .drive(qrCodeImageView.rx.isHidden)
                .disposed(by: disposeBag)

//            addressTextField.rx.text
//                .skip(while: {$0?.isEmpty == true})
//                .subscribe(onNext: {[weak self] address in
//                    self?.viewModel.enterWalletAddress(address)
//                })
//                .disposed(by: disposeBag)
        }

        @objc
        private func clearDestinationAddress() {
            viewModel.clearRecipientSearchText()
        }

        @objc
        private func scanQrCode() {
            viewModel.scanQRCode()
        }
    }
}
