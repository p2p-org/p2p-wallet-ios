//
//  ReceiveToken.ReceiveSolanaViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Resolver
import RxCocoa
import RxSwift

protocol ReceiveTokenSolanaViewModelType: BESceneModel {
    var pubkey: String { get }
    var tokenWallet: Wallet? { get }
    var username: String? { get }
    var hasExplorerButton: Bool { get }

    func showSOLAddressInExplorer()
    func copyAction()
    func shareAction(image: UIImage)
    func saveAction(image: UIImage)
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
            pubkey = solanaPubkey
            tokenWallet = solanaTokenWallet?.pubkey == solanaPubkey ? nil : solanaTokenWallet
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

        func shareAction(image: UIImage) {
            analyticsManager.log(event: .receiveUsercardShared)
            navigationSubject.accept(.share(address: pubkey, qrCode: image))
        }

        func saveAction(image: UIImage) {
            analyticsManager.log(event: .receiveQRSaved)
            imageSaver.save(image: image) { [weak self] result in
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
        }

        func showSOLAddressInExplorer() {
            analyticsManager.log(event: .receiveViewingExplorer)
            navigationSubject.accept(.showInExplorer(address: tokenWallet?.pubkey ?? pubkey))
        }
    }
}
