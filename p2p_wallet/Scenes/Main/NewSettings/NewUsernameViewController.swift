//
//  Settings.UsernameViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation
import Resolver

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
                ReceiveToken.QrCodeCard(
                    username: storage.getName(),
                    pubKey: storage.account?.publicKey.base58EncodedString,
                    token: .nativeSolana,
                    showCoinLogo: false
                )
                    .onCopy { [weak self] _ in
                        guard let self = self else { return }
                        guard let username = self.storage.getName() else { return }
                        self.clipboardManager.copyToClipboard(username)
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
