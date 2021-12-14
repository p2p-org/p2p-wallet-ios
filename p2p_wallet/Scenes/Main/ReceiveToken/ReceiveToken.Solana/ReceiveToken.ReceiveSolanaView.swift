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
    class ReceiveSolanaView: BECompositionView {
        private let disposeBag = DisposeBag()
        
        private let viewModel: ReceiveTokenSolanaViewModelType
        
        private var qrView: UIView!
        
        init(viewModel: ReceiveTokenSolanaViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                
                // QR Code Section
                UIStackView(axis: .vertical, alignment: .fill) {
                    
                    // QR Code
                    UIStackView(axis: .vertical, alignment: .fill) {
                        // Username
                        UILabel(textSize: 20, weight: .semibold, numberOfLines: 3, textAlignment: .center)
                            .setup { label in
                                guard let label = label as? UILabel else { return }
                                guard let username = viewModel.username,
                                      let nameWithDomain = viewModel.username?.withNameServiceDomain() else { return }
                                let text = NSMutableAttributedString(string: nameWithDomain)
                                text.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: username.count, length: text.length - username.count))
                                label.attributedText = text
                            }.padding(.init(x: 50, y: 26))
                        
                        // QR code
                        QrCodeView(size: 190, coinLogoSize: 32)
                            .setup { view in
                                qrView = view as! UIView
                            }
                            .with(string: viewModel.pubkey, token: viewModel.tokenWallet?.token)
                            .autoAdjustWidthHeightRatio(1)
                            .padding(.init(x: 50, y: 0))
                        
                        // Address
                        UILabel(textSize: 15, weight: .semibold, numberOfLines: 5, textAlignment: .center)
                            .setup { label in
                                guard let label = label as? UILabel else { return }
                                let address = NSMutableAttributedString(string: viewModel.pubkey)
                                address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: 0, length: 4))
                                address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: address.length - 4, length: 4))
                                label.attributedText = address
                            }.padding(.init(x: 50, y: 24))
                    }
                    
                    // Divider
                    UIView.defaultSeparator()
                    
                    // Action buttons
                    UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually) {
                        UIButton.text(text: L10n.copy, image: .copyIcon, tintColor: .h5887ff)
                            .onTap { [unowned self] in self.viewModel.copyAction() }
                        UIButton.text(text: L10n.share, image: .share2, tintColor: .h5887ff)
                            .onTap { [unowned self] in self.viewModel.shareAction(image: qrView.asImage()) }
                        UIButton.text(text: L10n.save, image: .imageIcon, tintColor: .h5887ff)
                            .onTap { [unowned self] in self.viewModel.saveAction(image: qrView.asImage()) }
                    }.padding(.init(x: 0, y: 4))
                    
                }.border(width: 1, color: .f2f2f7)
                    .box(cornerRadius: 12)
                    .shadow(color: .black, alpha: 0.05, y: 1, blur: 8)
                    .margin(.init(x: 0, y: 18))
                
                // Explore button
                WLStepButton.main(image: .external, imageSize: .init(width: 14, height: 14), text: L10n.viewInExplorer("Solana"))
                    .padding(.init(only: .top, inset: 18))
                    .onTap { [unowned self] in self.viewModel.showSOLAddressInExplorer() }
            }
        }
    }
}