//
//  NewUsernameViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2022.
//

import Foundation

class NewUsernameViewController: p2p_wallet.BaseViewController {
    let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init()
        navigationItem.title = L10n.yourP2pUsername
    }

    override func build() -> UIView {
        UIStackView(axis: .vertical, alignment: .fill) {
            BEScrollView(contentInsets: .init(x: 0, y: 8), spacing: 18) {
                ReceiveToken.QrCodeCard(
                    username: viewModel.name,
                    pubKey: viewModel.userSOLAddress,
                    token: .nativeSolana,
                    showCoinLogo: false
                )
                    .onCopy { [weak self] _ in
                        self?.viewModel.copyUsernameToClipboard()
                    }.onShare { [weak self] image in
                        self?.viewModel.share(image: image)
                    }.onSave { [weak self] image in
                        self?.viewModel.saveImage(image: image)
                    }

                UIView.greyBannerView {
                    UILabel(
                        text:
                        L10n
                            .yourP2PUsernameAllowsYouToReceiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletTokenList,
                        textSize: 15,
                        numberOfLines: 0
                    )
                }

            }.padding(.init(x: 18, y: 0))
        }
    }
}
