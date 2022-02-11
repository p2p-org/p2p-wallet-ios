//
//  Settings.UsernameViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation

extension Settings {
    class NewUsernameViewController: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        let viewModel: SettingsViewModelType
        
        init(viewModel: SettingsViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                NewWLNavigationBar(initialTitle: L10n.yourP2pUsername, separatorEnable: false)
                    .onBack { [unowned self] in back() }
                
                BEScrollView(contentInsets: .init(x: 0, y: 8), spacing: 18) {
                    ReceiveToken.QrCodeCard(
                            username: viewModel.getUsername(),
                            pubKey: viewModel.getUserAddress(),
                            token: .nativeSolana,
                            showCoinLogo: false)
                        .onCopy {  [unowned self] in viewModel.copyUsernameToClipboard() }
                        .onShare { [unowned self]  in viewModel.share() }
                        .onSave { [unowned self] in viewModel.save() }
                    
                    UIView.greyBannerView {
                        UILabel(
                            text:
                            L10n.yourP2PUsernameAllowsYouToReceiveAnyTokenWithinTheSolanaNetworkEvenIfItIsNotIncludedInYourWalletList,
                            textSize: 15,
                            numberOfLines: 0
                        )
                    }
                    
                }.padding(.init(x: 18, y: 0))
            }
        }
        
        private func save(image: UIImage) {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.saveImageCallback), nil)
        }
        
        @objc private func saveImageCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            if let error = error {
                showError(error)
            } else {
                viewModel.notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
            }
        }
    }
}
