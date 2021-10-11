//
//  UsernameVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/10/2021.
//

import Foundation

class UsernameVC: ProfileVCBase {
    @Injected private var accountStorage: KeychainAccountStorage
    private lazy var contentView = BERoundedCornerShadowView(
        shadowColor: .black.withAlphaComponent(0.05),
        radius: 8,
        offset: .init(width: 0, height: 1),
        opacity: 1,
        cornerRadius: 12,
        contentInset: .init(x: 38, y: 24)
    )
    
    private lazy var addressLabel = UILabel(text: accountStorage.account?.publicKey.base58EncodedString, textSize: 14, weight: .medium, numberOfLines: 0, textAlignment: .center)
    
    override func setUp() {
        title = L10n.yourP2pUsername
        super.setUp()
        view.backgroundColor = .white.onDarkMode(.h1b1b1b)
        
        stackView.removeFromSuperview()
        scrollView.removeFromSuperview()
        
        let separator = UIView.defaultSeparator()
        view.addSubview(separator)
        separator.autoPinEdge(.top, to: .bottom, of: navigationBar)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 38, y: 20), excludingEdge: .top)
        stackView.autoPinEdge(.top, to: .bottom, of: separator, withOffset: 20)
        
        stackView.spacing = 0
        
        stackView.addArrangedSubviews {
            UILabel(
                text:
                    L10n.yourP2PUsernameAllowsYouToReceiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletList,
                textSize: 15,
                numberOfLines: 0,
                textAlignment: .center
            )
            
            BEStackViewSpacing(20)
            
            contentView
            
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
    }
    
    private func setUpContentView() {
        contentView.stackView.axis = .vertical
        contentView.stackView.spacing = 22
        contentView.stackView.addArrangedSubviews {
            UILabel(text: accountStorage.getName()?.withNameServiceDomain(), textSize: 21, weight: .semibold)
            ReceiveToken.QrCodeView(size: 220, coinLogoSize: 56)
                .with(string: accountStorage.account?.publicKey.base58EncodedString, token: .nativeSolana)
                .centeredHorizontallyView
            addressLabel
        }
        
        configureAddressLabel()
    }
    
    @objc private func copyToClipboardButtonDidTouch() {
        UIApplication.shared.copyToClipboard(accountStorage.getName()?.withNameServiceDomain(), alert: true, alertMessage: L10n.copiedToClipboard)
    }
    
    @objc private func shareButtonDidTouch() {
        guard let name = accountStorage.getName()?.withNameServiceDomain() else {return}
        let vc = UIActivityViewController(activityItems: [name], applicationActivities: nil)
        present(vc, animated: true, completion: nil)
    }
    
    @objc private func saveButtonDidTouch() {
        UIImageWriteToSavedPhotosAlbum(contentView.asImage(), self, #selector(saveImageCallback), nil)
    }
    
    @objc private func saveImageCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer)
    {
        if let error = error {
            showError(error)
        } else {
            UIApplication.shared.showToast(message: "✅ \(L10n.savedToPhotoLibrary)")
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

private extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
