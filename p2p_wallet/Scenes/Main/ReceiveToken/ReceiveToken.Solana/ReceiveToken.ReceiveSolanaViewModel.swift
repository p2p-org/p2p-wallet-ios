//
//  ReceiveToken.ReceiveSolanaViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveTokenSolanaViewModelType {
    var pubkey: String { get }
    var tokenWallet: Wallet? { get }
    
    func getUsername() -> String?
    
    func showSOLAddressInExplorer()
    func copyAction()
    func shareAction(image: UIImage)
    func saveAction(image: UIImage)
}

extension ReceiveToken {
    class ReceiveSolanaViewModel: NSObject {
        // MARK: - Dependencies
        @Injected private var nameStorage: NameStorageType
        @Injected private var analyticsManager: AnalyticsManagerType
        private let tokensRepository: TokensRepository
        private let navigationSubject: BehaviorRelay<NavigatableScene?>
        
        // MARK: - Properties
        let pubkey: String
        let tokenWallet: Wallet?
        private let disposeBag = DisposeBag()
        
        // MARK: - Subjects
        
        // MARK: - Initializers
        init(
            solanaPubkey: String,
            solanaTokenWallet: Wallet? = nil,
            tokensRepository: TokensRepository,
            navigationSubject: BehaviorRelay<NavigatableScene?>
        ) {
            self.pubkey = solanaPubkey
            self.tokensRepository = tokensRepository
            var tokenWallet = solanaTokenWallet
            if solanaTokenWallet?.pubkey == solanaPubkey {
                tokenWallet = nil
            }
            self.tokenWallet = tokenWallet
            self.navigationSubject = navigationSubject
        }
    }
}

extension ReceiveToken.ReceiveSolanaViewModel: ReceiveTokenSolanaViewModelType {
    func getUsername() -> String? {
        nameStorage.getName()
    }
    
    func copyAction() {
        analyticsManager.log(event: .receiveWalletAddressCopy)
        UIApplication.shared.copyToClipboard(pubkey, alertMessage: "✅ " + L10n.addressCopiedToClipboard)
    }
    
    func shareAction(image: UIImage) {
        analyticsManager.log(event: .receiveQrcodeShare)
        navigationSubject.accept(.share(qrCode: image))
    }
    
    func saveAction(image: UIImage) {
        analyticsManager.log(event: .receiveQrcodeSave)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveImageCallback), nil)
    }
    
    @objc private func saveImageCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            UIApplication.shared.showToast(message: "\(error.localizedDescription)")
        } else {
            UIApplication.shared.showToast(message: "✅ \(L10n.savedToPhotoLibrary)")
        }
    }
    
    func showSOLAddressInExplorer() {
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showInExplorer(address: pubkey))
    }
}

