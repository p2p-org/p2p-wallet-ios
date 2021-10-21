//
//  SendToken.AddressView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.10.2021.
//

import UIKit
import RxSwift

extension SendToken {
    final class AddressView: UIStackView {
        private let viewModel: SendTokenViewModelType
        private let disposeBag = DisposeBag()

        private let addressButton = AddressButton()
//        private lazy var addressTextField: UITextField = {
//            let textField = UITextField(height: 44, backgroundColor: .clear, placeholder: L10n.walletAddress, autocorrectionType: .none, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .no, horizontalPadding: 8)
//            textField.attributedPlaceholder = NSAttributedString(string: L10n.walletAddress, attributes: [.foregroundColor: UIColor.a3a5ba.onDarkMode(.h5887ff)])
//            return textField
//        }()

        private let clearAddressButton = UIImageView(width: 24, height: 24, image: .closeFill, tintColor: UIColor.black.withAlphaComponent(0.6))
            .onTap(self, action: #selector(clearDestinationAddress))
        private let qrCodeImageView = UIImageView(width: 35, height: 35, image: .scanQr3, tintColor: .a3a5ba)
            .onTap(self, action: #selector(scanQrCode))

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        init(viewModel: SendTokenViewModelType) {
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

            [addressButton, clearAddressButton, qrCodeImageView].forEach(addArrangedSubview)
        }

        private func configureSubviews() {

        }

        private func bind() {
//            viewModel.receiverAddressDriver
//                .drive(addressTextField.rx.text)
//                .disposed(by: disposeBag)

//            viewModel.receiverAddressDriver
//                .map {[weak self] address in
//                    guard let address = address else {return true}
//                    return !address.matches(
//                        oneOf: .publicKey, .bitcoinAddress(isTestnet: self?.viewModel.isTestNet() ?? true)
//                    )
//                }
//                .drive(walletIconView.rx.isHidden)
//                .disposed(by: disposeBag)

            let destinationAddressInputEmpty = viewModel.receiverAddressDriver
                .map {$0 == nil || $0!.isEmpty}

            destinationAddressInputEmpty
                .drive(clearAddressButton.rx.isHidden)
                .disposed(by: disposeBag)

            let destinationAddressInputNotEmpty = destinationAddressInputEmpty
                .map {!$0}

            destinationAddressInputNotEmpty
                .drive(qrCodeImageView.rx.isHidden)
                .disposed(by: disposeBag)

            viewModel.currentAddressContentDriver
                .drive(addressButton.rx.addressContent)
                .disposed(by: disposeBag)

            addressButton.rx.tap
                .subscribe(onNext: { [weak viewModel] in
                    viewModel?.navigate(to: .selectRecipient)
                })
                .disposed(by: disposeBag)

//            addressTextField.rx.text
//                .skip(while: {$0?.isEmpty == true})
//                .subscribe(onNext: {[weak self] address in
//                    self?.viewModel.enterWalletAddress(address)
//                })
//                .disposed(by: disposeBag)
//
//            addressTextField.rx.controlEvent([.editingDidEnd])
//                .asObservable()
//                .subscribe(onNext: { [weak self] _ in
//                    self?.analyticsManager.log(event: .sendAddressKeydown)
//                })
//                .disposed(by: disposeBag)
        }

        @objc
        private func clearDestinationAddress() {
            viewModel.clearDestinationAddress()
        }

        @objc
        private func scanQrCode() {
            viewModel.scanQRCode()
        }

    }
}
