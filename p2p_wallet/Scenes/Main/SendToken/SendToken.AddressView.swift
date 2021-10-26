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

        private let clearAddressButton = UIImageView(width: 24, height: 24, image: .closeFill, tintColor: UIColor.black.withAlphaComponent(0.6))
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
            clearAddressButton.onTap(self, action: #selector(clearDestinationAddress))
            qrCodeImageView.onTap(self, action: #selector(scanQrCode))
        }

        private func bind() {
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
