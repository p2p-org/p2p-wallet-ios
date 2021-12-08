//
//  ReceiveToken.ReceiveSolanaView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension ReceiveToken {
    class ReceiveSolanaView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ReceiveTokenSolanaViewModelType
        
        // MARK: - Subviews
        private lazy var addressLabel: UIView = {
            let address = NSMutableAttributedString(string: viewModel.pubkey)
            address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: 0, length: 4))
            address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: address.length - 4, length: 4))
            
            let label = UILabel(textSize: 15, weight: .semibold, numberOfLines: 5, textAlignment: .center)
            label.attributedText = address
            
            return label
        }()
        
        private lazy var nameLabel: UIView = {
            guard let username = viewModel.getUsername(),
                  let nameWithDomain = viewModel.getUsername()?.withNameServiceDomain() else { return UIView() }
            
            let text = NSMutableAttributedString(string: nameWithDomain)
            text.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: username.count, length: text.length - username.count))
            
            let label = UILabel(textSize: 20, weight: .semibold, numberOfLines: 3, textAlignment: .center)
            label.attributedText = text
            return label
        }()
        
        lazy var qrCodeView = {
            UIStackView(axis: .vertical, alignment: .fill) {
                // Username
                nameLabel.padding(.init(x: 50, y: 26))
                
                // QR code
                QrCodeView(size: 190, coinLogoSize: 32)
                    .with(string: viewModel.pubkey, token: viewModel.tokenWallet?.token)
                    .autoAdjustWidthHeightRatio(1)
                    .padding(.init(x: 50, y: 0))
                
                // Address
                addressLabel.padding(.init(x: 50, y: 24))
            }
        }()
        
        fileprivate let copyButton: UIButton = UIButton.text(text: L10n.copy, image: .copyIcon, tintColor: .h5887ff)
        fileprivate let shareButton: UIButton = UIButton.text(text: L10n.share, image: .share2, tintColor: .h5887ff)
        fileprivate let saveButton: UIButton = UIButton.text(text: L10n.save, image: .imageIcon, tintColor: .h5887ff)
        
        // MARK: - Initializers
        init(viewModel: ReceiveTokenSolanaViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        // MARK: - Layout
        private func layout() {
            
            let stackView = UIStackView(axis: .vertical, spacing: 24, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .vertical, alignment: .fill) {
                    qrCodeView
                    
                    UIView.defaultSeparator()
                    
                    // Action buttons
                    UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually) {
                        copyButton
                        shareButton
                        saveButton
                    }.padding(.init(x: 0, y: 4))
                    
                }.border(width: 1, color: .f2f2f7)
                    .box(cornerRadius: 12)
                    .shadow(color: .black, alpha: 0.05, y: 1, blur: 8)
                    .margin(.init(x: 0, y: 18))
                
                WLStepButton.main(image: .external, imageSize: .init(width: 14, height: 14), text: L10n.viewInExplorer("Solana"))
                    .onTap(self, action: #selector(showExplorer))
                    .padding(.init(only: .top, inset: 18))
            }
            
            // add stackView
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))
        }
        
        private func bind() {
            copyButton.addTarget(self, action: #selector(_copy), for: .touchUpInside)
            shareButton.addTarget(self, action: #selector(_share), for: .touchUpInside)
            saveButton.addTarget(self, action: #selector(_save), for: .touchUpInside)
        }
        
        @objc private func showExplorer() {
            viewModel.showSOLAddressInExplorer()
        }
        
        @objc private func _copy() {
            viewModel.copyAction()
        }
        
        @objc private func _share() {
            viewModel.shareAction(image: qrCodeView.asImage())
        }
        
        @objc private func _save() {
            viewModel.saveAction(image: qrCodeView.asImage())
        }
    }
}
