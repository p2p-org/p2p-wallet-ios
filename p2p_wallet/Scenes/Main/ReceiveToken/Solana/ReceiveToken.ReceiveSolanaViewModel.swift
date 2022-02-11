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
    var hasExplorerButton: Bool { get }

    func showSOLAddressInExplorer()
    func copyAction()
    func shareAction()
    func saveAction()
}

extension ReceiveToken {
    class SolanaViewModel: NSObject, ReceiveTokenSolanaViewModelType {
        @Injected private var nameStorage: NameStorageType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManger: ClipboardManagerType
        @Injected private var notificationsService: NotificationsServiceType
        @Injected private var tokensRepository: TokensRepository
        private let navigationSubject: PublishRelay<NavigatableScene?>
        
        let pubkey: String
        let tokenWallet: Wallet?
        let hasExplorerButton: Bool
        private let disposeBag = DisposeBag()
        
        init(
            solanaPubkey: String,
            solanaTokenWallet: Wallet? = nil,
            navigationSubject: PublishRelay<NavigatableScene?>,
            hasExplorerButton: Bool
        ) {
            self.pubkey = solanaPubkey
            self.tokenWallet = solanaTokenWallet?.pubkey == solanaPubkey ? nil : solanaTokenWallet
            self.navigationSubject = navigationSubject
            self.hasExplorerButton = hasExplorerButton
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
        
        func shareAction() {
            analyticsManager.log(event: .receiveQrcodeShare)
    
            generateQrCode()
                .subscribe(onSuccess: { [weak self] image in self?.navigationSubject.accept(.share(qrCode: image)) })
                .disposed(by: disposeBag)
        }
        
        func saveAction() {
            analyticsManager.log(event: .receiveQrcodeSave)
    
            generateQrCode()
                .subscribe(onSuccess: { [weak self] image in
                    guard let self = self else { return }
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.saveImageCallback), nil)
                })
                .disposed(by: disposeBag)
        }
    
        func generateQrCode() -> Single<UIImage> {
            let render: QrCodeImageRender = Resolver.resolve()
            return render.render(username: username, address: pubkey, token: .renBTC, showTokenIcon: true)
        }
        
        @objc private func saveImageCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
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
