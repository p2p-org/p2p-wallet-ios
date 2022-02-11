//
// Created by Giang Long Tran on 27.12.21.
//

import Foundation
import RxSwift
import RxCocoa

extension ReceiveToken {
    class QrCodeCard: BECompositionView {
        let disposeBag = DisposeBag()
        
        var username: String? {
            didSet {
                guard let username = username else { return }
                updateUsername(username)
            }
        }
        var pubKey: String? {
            didSet {
                updatePubKey(pubKey)
                qrView.with(string: pubKey, token: token)
            }
        }
        
        var token: SolanaSDK.Token? {
            didSet { qrView.with(string: pubKey, token: token) }
        }
        
        private let showCoinLogo: Bool
        
        private var onCopy: BEVoidCallback?
        private var onShare: BEVoidCallback?
        private var onSave: BEVoidCallback?
        
        private var pubKeyView: UILabel?
        private var usernameLabel: UILabel!
        private var qrView: QrCodeView!
        
        init(
            username: String? = nil,
            pubKey: String? = nil,
            token: SolanaSDK.Token? = nil,
            showCoinLogo: Bool = true
        ) {
            self.username = username
            self.pubKey = pubKey
            self.token = token
            self.showCoinLogo = showCoinLogo
            
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                
                // QR Code
                UIStackView(axis: .vertical, alignment: .fill) {
                    // Username
                    UILabel(textSize: 20, weight: .semibold, numberOfLines: 3, textAlignment: .center)
                        .setupWithType(UILabel.self) { label in
                            usernameLabel = label
                            guard let username = username else { return }
                            updateUsername(username)
                        }.padding(.init(x: 50, y: 26))
                    
                    // QR code
                    QrCodeView(size: 190, coinLogoSize: 32, showCoinLogo: showCoinLogo)
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
                        .onTap { [unowned self] in onCopy?() }
                    UIButton.text(text: L10n.share, image: .share2, tintColor: .h5887ff)
                        .onTap { [unowned self] in onShare?() }
                    UIButton.text(text: L10n.save, image: .imageIcon, tintColor: .h5887ff)
                        .onTap { [unowned self] in onSave?() }
                }.padding(.init(x: 0, y: 4))
                
            }.border(width: 1, color: .f2f2f7)
                .box(cornerRadius: 12)
                .shadow(color: .black, alpha: 0.05, y: 1, blur: 8)
        }
        
        private func updateUsername(_ username: String) {
            let text = NSMutableAttributedString(string: username.withNameServiceDomain())
            text.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: username.count, length: text.length - username.count))
            usernameLabel.attributedText = text
            usernameLabel.isHidden = username.isEmpty
        }
        
        private func updatePubKey(_ pubKey: String?) {
            guard let pubKey = pubKey else {
                pubKeyView?.text = ""
                return
            }
            
            let address = NSMutableAttributedString(string: pubKey)
            address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: 0, length: 4))
            address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: address.length - 4, length: 4))
            pubKeyView?.attributedText = address
        }
        
        func onCopy(callback: @escaping BEVoidCallback) -> Self {
            onCopy = callback
            return self
        }
        
        func onShare(callback: @escaping BEVoidCallback) -> Self {
            onShare = callback
            return self
        }
        
        func onSave(callback: @escaping BEVoidCallback) -> Self {
            onSave = callback
            return self
        }
    }
}

extension Reactive where Base: ReceiveToken.QrCodeCard {
    var username: Binder<String?> {
        Binder(base) { view, username in view.username = username }
    }
    
    var pubKey: Binder<String?> {
        Binder(base) { view, pubKey in view.pubKey = pubKey }
    }
    
    var token: Binder<SolanaSDK.Token?> {
        Binder(base) { view, token in view.token = token }
    }
}
