//
// Created by Giang Long Tran on 27.12.21.
//

import Combine
import Foundation
import KeyAppUI
import Resolver
import SolanaSwift

extension ReceiveToken {
    class QrCodeCard: BECompositionView {
        @Injected var qrImageRender: QrCodeImageRender
        var subscriptions = [AnyCancellable]()

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

        var token: Token? {
            didSet { qrView.with(string: pubKey, token: token) }
        }

        private let showCoinLogo: Bool

        private var onCopy: BECallback<String?>?
        private var onShare: BECallback<UIImage>?
        private var onSave: BECallback<UIImage>?

        private var pubKeyView: UILabel?
        private var usernameLabel: UILabel!
        private var qrView: QrCodeView!

        init(
            username: String? = nil,
            pubKey: String? = nil,
            token: Token? = nil,
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
                        .setup { label in
                            usernameLabel = label
                            guard let username = username else { return }
                            updateUsername(username)
                        }.padding(.init(x: 50, y: 26))

                    // QR code
                    QrCodeView(size: 190, coinLogoSize: 32, showCoinLogo: showCoinLogo)
                        .setup { view in qrView = view }
                        .with(string: pubKey, token: token)
                        .autoAdjustWidthHeightRatio(1)
                        .padding(.init(x: 50, y: 0))

                    // Address
                    UILabel(textSize: 15, weight: .semibold, numberOfLines: 5, textAlignment: .center)
                        .setup { label in
                            pubKeyView = label
                            updatePubKey(pubKey)
                        }.padding(.init(x: 50, y: 24))
                }

                // Divider
                UIView.defaultSeparator()

                // Action buttons
                UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually) {
                    UIButton.text(text: L10n.copy, image: tinted(image: .copyIcon), tintColor: Asset.Colors.night.color)
                        .onTap { [unowned self] in self.onCopy?(pubKey) }
                    UIButton.text(text: L10n.share, image: tinted(image: .share2), tintColor: Asset.Colors.night.color)
                        .onTap { [unowned self] in
                            let image = try await qrImageRender.render(
                                username: username,
                                address: pubKey,
                                token: token,
                                showTokenIcon: showCoinLogo
                            )
                            await MainActor.run { [weak self] in
                                self?.onShare?(image)
                            }
                        }
                    UIButton.text(text: L10n.save, image: tinted(image: .imageIcon), tintColor: Asset.Colors.night.color)
                        .onTap { [unowned self] in
                            let image = try await qrImageRender.render(
                                username: username,
                                address: pubKey,
                                token: token,
                                showTokenIcon: showCoinLogo
                            )
                            await MainActor.run { [weak self] in
                                self?.onSave?(image)
                            }
                        }
                }.padding(.init(x: 0, y: 4))

            }.border(width: 1, color: .f2f2f7)
                .box(cornerRadius: 12)
                .shadow(color: .black, alpha: 0.05, y: 1, blur: 8)
        }

        private func updateUsername(_ username: String) {
            let text = NSMutableAttributedString(string: username.withNameServiceDomain())
            text.addAttribute(
                .foregroundColor,
                value: UIColor.gray,
                range: NSRange(location: username.count, length: text.length - username.count)
            )
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
            address.addAttribute(
                .foregroundColor,
                value: UIColor.h5887ff,
                range: NSRange(location: address.length - 4, length: 4)
            )
            pubKeyView?.attributedText = address
        }

        private func tinted(image: UIImage) -> UIImage {
            image.withTintColor(Asset.Colors.night.color)
        }

        func onCopy(callback: @escaping BECallback<String?>) -> Self {
            onCopy = callback
            return self
        }

        func onShare(callback: @escaping BECallback<UIImage>) -> Self {
            onShare = callback
            return self
        }

        func onSave(callback: @escaping BECallback<UIImage>) -> Self {
            onSave = callback
            return self
        }
    }
}
