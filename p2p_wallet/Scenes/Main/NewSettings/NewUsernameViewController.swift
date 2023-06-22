//
//  Settings.UsernameViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation
import Resolver
import KeyAppUI
import SolanaSwift

class NewUsernameViewController: p2p_wallet.BaseViewController {
    @Injected private var imageSaver: ImageSaverType
    @Injected private var notificationsService: NotificationService
    @Injected private var storage: ICloudStorageType & AccountStorageType & NameStorageType & PincodeStorageType
    @Injected private var clipboardManager: ClipboardManagerType

    override init() {
        super.init()
        navigationItem.title = L10n.yourUsername
    }

    override func build() -> UIView {
        UIStackView(axis: .vertical, alignment: .fill) {
            BEScrollView(contentInsets: .init(x: 0, y: 8), spacing: 18) {
                QrCodeCard(
                    username: storage.getName(),
                    pubKey: storage.account?.publicKey.base58EncodedString,
                    token: .nativeSolana,
                    showCoinLogo: false
                )
                    .onCopy { [weak self] _ in
                        guard let self = self else { return }
                        guard let publicKey = self.storage.account?.publicKey.base58EncodedString else { return }
                        self.clipboardManager.copyToClipboard(publicKey)
                        self.notificationsService.showInAppNotification(.done(L10n.copiedToClipboard))
                    }.onShare { [weak self] image in
                        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                        self?.present(vc, animated: true, completion: nil)
                    }.onSave { [weak self] image in
                        self?.imageSaver.save(image: image) { [weak self] result in
                            switch result {
                            case .success:
                                self?.notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
                            case let .failure(error):
                                switch error {
                                case .noAccess:
                                    guard let self = self else { return }
                                    PhotoLibraryAlertPresenter().present(on: self)
                                case .restrictedRightNow:
                                    break
                                case let .unknown(error):
                                    self?.notificationsService.showInAppNotification(.error(error))
                                }
                            }
                        }
                    }

                UIView.greyBannerView {
                    UILabel(
                        text:
                        L10n
                            .yourUsernameAllowsYouToReceiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletTokenList,
                        textSize: 15,
                        numberOfLines: 0
                    )
                }

            }.padding(.init(x: 18, y: 0))
        }
    }
}

private class QrCodeCard: BECompositionView {
    @Injected var qrImageRender: QrCodeImageRender
    
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
                    .onTap {
                        Task { [weak self] in
                            guard let self else { return }
                            let image = try await self.qrImageRender.render(
                                username: self.username,
                                address: self.pubKey,
                                token: self.token,
                                showTokenIcon: self.showCoinLogo
                            )
                            self.onShare?(image)
                        }
                    }
                UIButton.text(text: L10n.save, image: tinted(image: .imageIcon), tintColor: Asset.Colors.night.color)
                    .onTap {
                        Task { [weak self] in
                            guard let self else { return }
                            let image = try await self.qrImageRender.render(
                                username: self.username,
                                address: self.pubKey,
                                token: self.token,
                                showTokenIcon: self.showCoinLogo
                            )
                            self.onSave?(image)
                        }
                    }
            }.padding(.init(x: 0, y: 4))
            
        }.border(width: 1, color: .f2f2f7)
            .box(cornerRadius: 12)
            .shadow(color: .black, alpha: 0.05, y: 1, blur: 8)
    }
    
    private func updateUsername(_ username: String) {
        let text = NSMutableAttributedString(string: username)
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

private class QrCodeView: BEView {
    private let size: CGFloat
    private let coinLogoSize: CGFloat
    private let showCoinLogo: Bool
    
    private lazy var qrCodeImageView = QrCodeImageView(backgroundColor: .clear)
    private lazy var logoImageView: CoinLogoImageView = {
        let imageView = CoinLogoImageView(size: coinLogoSize)
        imageView.layer.borderWidth = 4
        imageView.layer.borderColor = UIColor.textWhite.cgColor
        imageView.layer.cornerRadius = coinLogoSize / 2
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    init(size: CGFloat, coinLogoSize: CGFloat, showCoinLogo: Bool = true) {
        self.size = size
        self.coinLogoSize = coinLogoSize
        self.showCoinLogo = showCoinLogo
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        configureForAutoLayout()
        autoSetDimensions(to: .init(width: size, height: size))
        logoImageView.autoSetDimensions(to: .init(width: coinLogoSize, height: coinLogoSize))
        
        addSubview(qrCodeImageView)
        qrCodeImageView.autoPinEdgesToSuperviewEdges()
        
        if showCoinLogo {
            addSubview(logoImageView)
            logoImageView.autoCenterInSuperview()
        }
    }
    
    func setUp(string: String?, token: Token? = nil) {
        qrCodeImageView.setQrCode(string: string)
        logoImageView.setUp(token: token ?? .nativeSolana)
    }
    
    @discardableResult
    func with(string: String?, token: Token? = nil) -> Self {
        setUp(string: string, token: token)
        return self
    }
}

private class QrCodeImageView: UIImageView {
    fileprivate func setQrCode(string: String?) {
        guard let string = string else {
            image = nil
            return
        }
        
        if let imageFromCache = UIImageView.qrCodeCache.object(forKey: string as NSString) {
            image = imageFromCache
            return
        }
        
        let data = string.data(using: String.Encoding.ascii)
        
        DispatchQueue.global().async {
            var image: UIImage?
            if let filter = CIFilter(name: "CIQRCodeGenerator") {
                filter.setValue(data, forKey: "inputMessage")
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                
                if let output = filter.outputImage?.transformed(by: transform) {
                    let qrCode = UIImage(ciImage: output)
                    image = qrCode
                    UIImageView.qrCodeCache.setObject(qrCode, forKey: string as NSString)
                }
            }
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}

private final class PhotoLibraryAlertPresenter {
    func present(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: L10n.allowAccessToSaveYourPhotos,
            message: L10n.thisIsRequiredForTheAppToSaveGeneratedQRCodesOrBackUpOfYourSeedPhrasesToYourPhotoLibrary,
            preferredStyle: .alert
        )
        
        let notNowAction = UIAlertAction(
            title: L10n.cancel,
            style: .cancel,
            handler: nil
        )
        
        alert.addAction(notNowAction)
        
        let openSettingsAction = UIAlertAction(
            title: L10n.openSettings,
            style: .default,
            handler: goToAppPrivacySettings()
        )
        
        alert.addAction(openSettingsAction)
        
        viewController.present(alert, animated: true)
    }
    
    private func goToAppPrivacySettings() -> (UIAlertAction) -> Void {
        { _ in
            guard
                let url = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(url)
            else {
                return assertionFailure("Not able to open App privacy settings")
            }
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
