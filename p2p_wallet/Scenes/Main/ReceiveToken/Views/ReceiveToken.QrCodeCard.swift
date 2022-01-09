//
// Created by Giang Long Tran on 27.12.21.
//

import Foundation
import RxSwift
import RxCocoa

extension ReceiveToken {
    class QrCodeCard: BECompositionView {
        @Injected var qrImageRender: QrCodeImageRender
        let disposeBag = DisposeBag()
        
        let username: String?
        var pubKey: String? {
            didSet {
                updatePubKey(pubKey)
                qrView.with(string: pubKey, token: token)
            }
        }
        var token: SolanaSDK.Token? {
            didSet { qrView.with(string: pubKey, token: token) }
        }
        
        let onCopy: BECallback<String?>?
        let onShare: BECallback<UIImage>?
        let onSave: BECallback<UIImage>?
        
        fileprivate var pubKeyView: UILabel?
        fileprivate var qrView: QrCodeView!
        
        fileprivate func updatePubKey(_ pubKey: String?) {
            guard let pubKey = pubKey else {
                pubKeyView?.text = ""
                return
            }
            
            let address = NSMutableAttributedString(string: pubKey)
            address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: 0, length: 4))
            address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: address.length - 4, length: 4))
            pubKeyView?.attributedText = address
        }
        
        init(
            username: String? = nil,
            pubKey: String? = nil,
            token: SolanaSDK.Token? = nil,
            onCopy: BECallback<String?>? = nil,
            onShare: BECallback<UIImage>? = nil,
            onSave: BECallback<UIImage>? = nil
        ) {
            self.username = username
            self.pubKey = pubKey
            self.token = token
            self.onCopy = onCopy
            self.onShare = onShare
            self.onSave = onSave
            
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                
                // QR Code
                UIStackView(axis: .vertical, alignment: .fill) {
                    // Username
                    if username != nil {
                        UILabel(textSize: 20, weight: .semibold, numberOfLines: 3, textAlignment: .center)
                            .setup { label in
                                guard let label = label as? UILabel else { return }
                                guard let username = username else { return }
                                let text = NSMutableAttributedString(string: username.withNameServiceDomain())
                                text.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: username.count, length: text.length - username.count))
                                label.attributedText = text
                            }.padding(.init(x: 50, y: 26))
                    } else {
                        UIView().frame(height: 33)
                    }
                    
                    // QR code
                    QrCodeView(size: 190, coinLogoSize: 32)
                        .setupWithType(QrCodeView.self) { view in qrView = view }
                        .with(string: pubKey, token: token)
                        .autoAdjustWidthHeightRatio(1)
                        .padding(.init(x: 50, y: 0))
                    
                    // Address
                    UILabel(textSize: 15, weight: .semibold, numberOfLines: 5, textAlignment: .center)
                        .setupWithType(UILabel.self) { label in
                            pubKeyView = label
                            updatePubKey(pubKey)
                        }.padding(.init(x: 50, y: 24))
                }
                
                // Divider
                UIView.defaultSeparator()
                
                // Action buttons
                UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually) {
                    UIButton.text(text: L10n.copy, image: .copyIcon, tintColor: .h5887ff)
                        .onTap { [unowned self] in self.onCopy?(pubKey) }
                    UIButton.text(text: L10n.share, image: .share2, tintColor: .h5887ff)
                        .onTap { [unowned self] in
                            qrImageRender.render(username: username, address: pubKey, token: token).subscribe(onSuccess: { image in
                                self.onShare?(image)
                            })
                        }
                    UIButton.text(text: L10n.save, image: .imageIcon, tintColor: .h5887ff)
                        .onTap { [unowned self] in
                            qrImageRender.render(username: username, address: pubKey, token: token).subscribe(onSuccess: { image in
                                self.onSave?(image)
                            })
                        }
                }.padding(.init(x: 0, y: 4))
                
            }.border(width: 1, color: .f2f2f7)
                .box(cornerRadius: 12)
                .shadow(color: .black, alpha: 0.05, y: 1, blur: 8)
        }
    }
}

extension Reactive where Base: ReceiveToken.QrCodeCard {
    var pubKey: Binder<String?> {
        Binder(base) { view, pubKey in view.pubKey = pubKey }
    }
    
    var token: Binder<SolanaSDK.Token?> {
        Binder(base) { view, token in view.token = token }
    }
}
