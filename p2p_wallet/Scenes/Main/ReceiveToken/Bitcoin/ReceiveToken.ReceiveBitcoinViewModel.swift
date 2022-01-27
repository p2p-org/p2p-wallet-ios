//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveTokenBitcoinViewModelType: AnyObject {
    var isReceivingRenBTCDriver: Driver<Bool> { get }
    var conditionAcceptedDriver: Driver<Bool> { get }
    var addressDriver: Driver<String?> { get }
    var timerSignal: Signal<Void> { get }
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> { get }
    
    func getSessionEndDate() -> Date?
    func acceptConditionAndLoadAddress()
    func showReceivingStatuses()
    func copyToClipboard()
    func share(image: UIImage)
    func saveAction(image: UIImage)
    func showBTCAddressInExplorer()
}

extension ReceiveToken {
    class ReceiveBitcoinViewModel: NSObject {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Dependencies
        @Injected private var renVMService: RenVMLockAndMintServiceType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected var notificationsService: NotificationsServiceType
        private let navigationSubject: PublishRelay<NavigatableScene?>
        @Injected private var associatedTokenAccountHandler: AssociatedTokenAccountHandler
        
        // MARK: - Subjects
        private let isReceivingRenBTCSubject = BehaviorRelay<Bool>(value: true)
        private lazy var createRenBTCSubject: LoadableRelay<String> = .init(
            request: associatedTokenAccountHandler
                .createAssociatedTokenAccount(tokenMint: .renBTCMint, isSimulation: false)
                .catch {error in
                    if error.isAlreadyInUseSolanaError {
                        return .just("")
                    }
                    throw error
                }
        )
        private let timerSubject = PublishRelay<Void>()
        
        // MARK: - Initializers
        init(
            navigationSubject: PublishRelay<NavigatableScene?>,
            isRenBTCWalletCreated: Bool
        ) {
            self.navigationSubject = navigationSubject

            super.init()
            
            if isRenBTCWalletCreated {
                createRenBTCSubject.accept(nil, state: .loaded)
            }
            
            bind()
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        func acceptConditionAndLoadAddress() {
            renVMService.acceptConditionAndLoadAddress()
        }
        
        private func bind() {
            Timer.observable(seconds: 1)
                .bind(to: timerSubject)
                .disposed(by: disposeBag)
            
            timerSubject
                .subscribe(onNext: { [weak self] in
                    guard let endAt = self?.getSessionEndDate() else { return }
                    if Date() >= endAt {
                        self?.renVMService.expireCurrentSession()
                    }
                })
                .disposed(by: disposeBag)
        }
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    var isReceivingRenBTCDriver: Driver<Bool> {
        isReceivingRenBTCSubject.asDriver()
    }

    var conditionAcceptedDriver: Driver<Bool> {
        renVMService.conditionAcceptedDriver
    }
    
    var addressDriver: Driver<String?> {
        renVMService.addressDriver
    }
    
    var timerSignal: Signal<Void> {
        timerSubject.asSignal()
    }

    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {
        renVMService.processingTxsDriver
    }
    
    func getSessionEndDate() -> Date? {
        renVMService.getSessionEndDate()
    }
    
    func copyToClipboard() {
        guard let address = renVMService.getCurrentAddress() else { return }
        clipboardManager.copyToClipboard(address)
        analyticsManager.log(event: .receiveAddressCopy)
    }
    
    func share(image: UIImage) {
        analyticsManager.log(event: .receiveAddressShare)
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
    
    func showBTCAddressInExplorer() {
        guard let address = renVMService.getCurrentAddress() else { return }
        analyticsManager.log(event: .receiveViewExplorerOpen)
        navigationSubject.accept(.showBTCExplorer(address: address))
    }
        
    func showReceivingStatuses() {
        navigationSubject.accept(.showRenBTCReceivingStatus)
    }
}
