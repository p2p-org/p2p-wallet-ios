//
//  Settings.UsernameViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation

extension Settings {
    class UsernameViewController: BaseViewController {
        private lazy var contentView = BERoundedCornerShadowView(
            shadowColor: .black.withAlphaComponent(0.05),
            radius: 8,
            offset: .init(width: 0, height: 1),
            opacity: 1,
            cornerRadius: 12,
            contentInset: .init(x: 38, y: 24)
        )
        
        private lazy var nameLabel = UILabel(textSize: 21, weight: .semibold)
        private lazy var qrCodeView = ReceiveToken.QrCodeView(size: 220, coinLogoSize: 56)
        private lazy var addressLabel = UILabel(text: viewModel.getUserAddress(), textSize: 14, weight: .medium, numberOfLines: 0, textAlignment: .center)
        
        override func setUp() {
            super.setUp()
            navigationBar.titleLabel.text = L10n.yourP2pUsername
            view.backgroundColor = .white.onDarkMode(.h1b1b1b)
            
            stackView.setCustomSpacing(20, after: stackView.arrangedSubviews[1]) // after separator
            stackView.addArrangedSubviews {
                UILabel(
                    text:
                        L10n.yourP2PUsernameAllowsYouToReceiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletList,
                    textSize: 15,
                    numberOfLines: 0,
                    textAlignment: .center
                )
                    .padding(.init(x: 40, y: 0))
                
                BEStackViewSpacing(20)
                
                contentView.padding(.init(x: 40, y: 0))
                
                BEStackViewSpacing(30)
                
                UIStackView(axis: .horizontal, spacing: 32, alignment: .fill, distribution: .fillEqually) {
                    UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill) {
                        UIImageView(width: 48, height: 48, image: .buttonCopySquare)
                        UILabel(text: L10n.copy, textSize: 15, weight: .medium, textColor: .h5887ff, textAlignment: .center)
                    }
                        .onTap(self, action: #selector(copyToClipboardButtonDidTouch))
                    
                    UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill) {
                        UIImageView(width: 48, height: 48, image: .buttonShareSquare)
                        UILabel(text: L10n.share, textSize: 15, weight: .medium, textColor: .h5887ff, textAlignment: .center)
                    }
                        .onTap(self, action: #selector(shareButtonDidTouch))
                    
                    UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill) {
                        UIImageView(width: 48, height: 48, image: .buttonSaveSquare)
                        UILabel(text: L10n.save, textSize: 15, weight: .medium, textColor: .h5887ff, textAlignment: .center)
                    }
                        .onTap(self, action: #selector(saveButtonDidTouch))
                }
                    .centeredHorizontallyView
                
                UIView.spacer
            }
            
            setUpContentView()
            qrCodeView.setUp(string: viewModel.getUserAddress(), token: .nativeSolana)
        }
        
        override func bind() {
            super.bind()
            viewModel.usernameDriver
                .drive(nameLabel.rx.text)
                .disposed(by: disposeBag)
        }
        
        private func setUpContentView() {
            contentView.stackView.axis = .vertical
            contentView.stackView.spacing = 22
            contentView.stackView.addArrangedSubviews {
                nameLabel
                qrCodeView
                    .centeredHorizontallyView
                addressLabel
            }
            
            configureAddressLabel()
        }
        
        @objc private func copyToClipboardButtonDidTouch() {
            viewModel.copyUsernameToClipboard()
        }
        
        @objc private func shareButtonDidTouch() {
            viewModel.shareUsername()
        }
        
        @objc private func saveButtonDidTouch() {
            UIImageWriteToSavedPhotosAlbum(contentView.asImage(), self, #selector(saveImageCallback), nil)
        }
        
        @objc private func saveImageCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer)
        {
            if let error = error {
                showError(error)
            } else {
                viewModel.notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
            }
        }
        
        private func configureAddressLabel() {
            guard let text = addressLabel.text,
                  text.count > 10 else {return}
            let aStr = NSMutableAttributedString()
                .text(text, size: 14, weight: .medium)
            aStr.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: 0, length: 4))
            aStr.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: text.count - 4, length: 4))
            addressLabel.attributedText = aStr
        }
    }
}
