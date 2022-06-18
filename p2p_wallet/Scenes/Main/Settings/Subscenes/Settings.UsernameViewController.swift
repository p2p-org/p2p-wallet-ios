//
//  Settings.UsernameViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation

extension Settings {
    class NewUsernameViewController: p2p_wallet.BaseViewController {
        let viewModel: SettingsViewModelType

        init(viewModel: SettingsViewModelType) {
            self.viewModel = viewModel
            super.init()
            navigationItem.title = L10n.yourP2pUsername
        }

        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                BEScrollView(contentInsets: .init(x: 0, y: 8), spacing: 18) {
                    ReceiveToken.QrCodeCard(
                        username: viewModel.getUsername(),
                        pubKey: viewModel.getUserAddress(),
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
                                .yourP2PUsernameAllowsYouToReceiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletList,
                            textSize: 15,
                            numberOfLines: 0
                        )
                    }

                }.padding(.init(x: 18, y: 0))
            }
        }
    }
}
