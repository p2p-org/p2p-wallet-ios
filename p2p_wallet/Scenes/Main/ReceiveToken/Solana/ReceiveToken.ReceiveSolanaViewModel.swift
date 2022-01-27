//
//  ReceiveToken.ReceiveSolanaViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveTokenSolanaViewModelType: BESceneModel {
    var pubkey: String { get }
    var tokenWallet: Wallet? { get }
    var username: String? { get }
    
    func showSOLAddressInExplorer()
    func copyAction()
    func shareAction(image: UIImage)
    func saveAction(image: UIImage)
}

extension ReceiveToken {
    class SolanaViewModel: NSObject, ReceiveTokenSolanaViewModelType {
        @Injected private var nameStorage: NameStorageType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManger: ClipboardManagerType
        @Injected private var notificationsService: NotificationsServiceType
        private let navigationSubject: PublishRelay<NavigatableScene?>
        
        let pubkey: String
        let tokenWallet: Wallet?

        init(
            solanaPubkey: String,
            solanaTokenWallet: Wallet? = nil,
            navigationSubject: PublishRelay<NavigatableScene?>
        ) {
            self.pubkey = solanaPubkey
            self.tokenWallet = solanaTokenWallet?.pubkey == solanaPubkey ? nil : solanaTokenWallet
            self.navigationSubject = navigationSubject
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        var username: String? { nameStorage.getName() }
        
        func copyAction() {
            analyticsManager.log(event: .receiveWalletAddressCopy)
            clipboardManger.copyToClipboard(pubkey)
            notificationsService.showInAppNotification(.done(L10n.addressCopiedToClipboard))
        }
        
        func shareAction(image: UIImage) {
            analyticsManager.log(event: .receiveQrcodeShare)
            navigationSubject.accept(.share(qrCode: image))
        }
        
        func saveAction(image: UIImage) {
            analyticsManager.log(event: .receiveQrcodeSave)
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveImageCallback), nil)
        }
        
        @objc private func saveImageCallback(_: UIImage, didFinishSavingWithError error: Error?, _: UnsafeRawPointer) {
            if let error = error {
                notificationsService.showInAppNotification(.error(error))
            } else {
                notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
            }
        }
        
        func showSOLAddressInExplorer() {
            analyticsManager.log(event: .receiveViewExplorerOpen)
            navigationSubject.accept(.showInExplorer(address: tokenWallet?.pubkey ?? pubkey))
        }
    }
}
