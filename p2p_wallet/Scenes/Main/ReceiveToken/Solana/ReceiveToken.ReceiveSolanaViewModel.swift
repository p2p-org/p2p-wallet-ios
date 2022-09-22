//
//  ReceiveToken.ReceiveSolanaViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import AnalyticsManager
import Combine
import Resolver
import SolanaSwift

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
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var clipboardManger: ClipboardManagerType
        @Injected private var notificationsService: NotificationService
        @Injected private var imageSaver: ImageSaverType
        private let navigationSubject: PassthroughSubject<NavigatableScene?, Never>

        let pubkey: String
        let tokenWallet: Wallet?
        let hasExplorerButton: Bool

        init(
            solanaPubkey: String,
            solanaTokenWallet: Wallet? = nil,
            navigationSubject: PassthroughSubject<NavigatableScene?, Never>,
            hasExplorerButton: Bool
        ) {
            pubkey = solanaPubkey
            tokenWallet = solanaTokenWallet?.pubkey == solanaPubkey ? nil : solanaTokenWallet
            self.navigationSubject = navigationSubject
            self.hasExplorerButton = hasExplorerButton
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }

        var username: String? { nameStorage.getName() }

        func copyAction() {
            analyticsManager.log(event: AmplitudeEvent.receiveWalletAddressCopy)
            clipboardManger.copyToClipboard(pubkey)
            notificationsService.showInAppNotification(.done(L10n.addressCopiedToClipboard))
        }

        func shareAction(image: UIImage) {
            analyticsManager.log(event: AmplitudeEvent.receiveUsercardShared)
            navigationSubject.send(.share(address: pubkey, qrCode: image))
        }

        func saveAction(image: UIImage) {
            analyticsManager.log(event: AmplitudeEvent.receiveQRSaved)
            imageSaver.save(image: image) { [weak self] result in
                switch result {
                case .success:
                    self?.notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
                case let .failure(error):
                    switch error {
                    case .noAccess:
                        self?.navigationSubject.send(.showPhotoLibraryUnavailable)
                    case .restrictedRightNow:
                        break
                    case let .unknown(error):
                        self?.notificationsService.showInAppNotification(.error(error))
                    }
                }
            }
        }

        func showSOLAddressInExplorer() {
            analyticsManager.log(event: AmplitudeEvent.receiveViewingExplorer)
            navigationSubject.send(.showInExplorer(address: tokenWallet?.pubkey ?? pubkey))
        }
    }
}
