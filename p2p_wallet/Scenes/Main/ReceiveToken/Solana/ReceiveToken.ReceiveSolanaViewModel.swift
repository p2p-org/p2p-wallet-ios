//
//  ReceiveToken.ReceiveSolanaViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import RxSwift
import RxCocoa
import Resolver

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
    class SolanaViewModel: ReceiveTokenSolanaViewModelType {
        @Injected private var nameStorage: NameStorageType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManger: ClipboardManagerType
        @Injected private var notificationsService: NotificationsServiceType
        @Injected private var tokensRepository: TokensRepository
        @Injected private var imageSaver: ImageSaverType
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
                .subscribe(onSuccess: { [weak self] image in self?.navigationSubject.accept(.share(address: self?.pubkey, qrCode: image)) })
                .disposed(by: disposeBag)
        }
        
        func saveAction() {
            analyticsManager.log(event: .receiveQrcodeSave)
            generateQrCode()
                .subscribe(onSuccess: { [weak self] image in
                    self?.imageSaver.save(image: image) { [weak self] result in
                        switch result {
                        case .success:
                            self?.notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
                        case let .failure(error):
                            switch error {
                            case .noAccess:
                                self?.navigationSubject.accept(.showPhotoLibraryUnavailable)
                            case .restrictedRightNow:
                                break
                            case let .unknown(error):
                                self?.notificationsService.showInAppNotification(.error(error))
                            }
                        }
                    }
                })
                .disposed(by: disposeBag)
        }

        func showSOLAddressInExplorer() {
            analyticsManager.log(event: .receiveViewExplorerOpen)
            navigationSubject.accept(.showInExplorer(address: tokenWallet?.pubkey ?? pubkey))
        }
            
        func generateQrCode() -> Single<UIImage> {
            let render: QrCodeImageRender = Resolver.resolve()
            return render.render(username: username, address: pubkey, token: .nativeSolana, showTokenIcon: true)
        }
    }
}
