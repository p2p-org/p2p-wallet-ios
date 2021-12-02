//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.TitleView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation
import UIKit
import RxSwift

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class TitleView: UIStackView {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private lazy var scanQrCodeButton = createButton(image: .scanQr, text: L10n.scanQR)
            .onTap(self, action: #selector(buttonScanQrDidTouch))
        private lazy var separator = UIView(width: 1, height: 20, backgroundColor: .f6f6f8.onDarkMode(.white))
        private lazy var pasteQrCodeButton = createButton(image: .buttonPaste, text: L10n.paste.uppercaseFirst)
            .onTap(self, action: #selector(buttonPasteDidTouch))
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            set(axis: .horizontal, spacing: 16, alignment: .top, distribution: .fill)
            addArrangedSubviews {
                UILabel(text: L10n.to, textSize: 15, weight: .medium)
                UIView.spacer
                scanQrCodeButton
                separator
                pasteQrCodeButton
            }
            bind()
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bind() {
            let didFinishSearchingDriver = viewModel.inputStateDriver
                .map {$0 != .searching}
                .distinctUntilChanged()
            
            didFinishSearchingDriver
                .drive(scanQrCodeButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            didFinishSearchingDriver
                .drive(pasteQrCodeButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            didFinishSearchingDriver
                .drive(separator.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func buttonPasteDidTouch() {
            viewModel.userDidTapPaste()
        }
        
        @objc private func buttonScanQrDidTouch() {
            viewModel.navigate(to: .scanQrCode)
        }
        
        // MARK: - View builders
        private func createButton(image: UIImage, text: String) -> UIView {
            UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                UIImageView(width: 20, height: 20, image: image, tintColor: .h5887ff)
                UILabel(text: text, textSize: 15, weight: .medium, textColor: .h5887ff)
            }
        }
    }
}
