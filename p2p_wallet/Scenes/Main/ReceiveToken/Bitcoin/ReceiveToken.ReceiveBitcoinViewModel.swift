//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxCocoa
import RxSwift

enum ReceiveTokenBitcoinViewModelStatus {
    case ready
    case needAcceptCondition
    case needCreateAccount
    case needTopUpAccount
    case unknown(error: Error)
}

protocol ReceiveTokenBitcoinViewModelType: AnyObject {
    var notificationsService: NotificationsServiceType { get }
    var isReceivingRenBTCDriver: Driver<Bool> { get }
    var isLoadingDriver: Driver<Bool> { get }
    var errorDriver: Driver<String?> { get }
    var renBTCWalletCreatingDriver: Driver<Loadable<String>> { get }
    var conditionAcceptedDriver: Driver<Bool> { get }
    var addressDriver: Driver<String?> { get }
    var timerSignal: Signal<Void> { get }
    var minimumTransactionAmountDriver: Driver<Loadable<Double>> { get }
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> { get }
    var hasExplorerButton: Bool { get }

    var isReceivingRentBTC: Bool { get }
    var isConditionAccepted: Bool { get }

    func reload()
    func reloadMinimumTransactionAmount()
    func getSessionEndDate() -> Date?
    func acceptConditionAndLoadAddress()
    func toggleIsReceivingRenBTC(isReceivingRenBTC: Bool)
    func showReceivingStatuses()
    func copyToClipboard()
    func share(image: UIImage)
    func saveAction(image: UIImage)
    func showBTCAddressInExplorer()
    func getStatus() -> Single<ReceiveTokenBitcoinViewModelStatus>
}

extension ReceiveToken {
    class ReceiveBitcoinViewModel: NSObject {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        let hasExplorerButton: Bool

        // MARK: - Dependencies
        @Injected private var renVMService: RenVMLockAndMintServiceType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected var notificationsService: NotificationsServiceType
        private let navigationSubject: PublishRelay<NavigatableScene?>
        @Injected private var associatedTokenAccountHandler: AssociatedTokenAccountHandler
        @Injected var rentBTCService: RentBTC.Service

        // MARK: - Subjects
        private let isReceivingRenBTCSubject = BehaviorRelay<Bool>(value: true)
        private lazy var createRenBTCSubject: LoadableRelay<String> = .init(
            request:
                associatedTokenAccountHandler
                .createAssociatedTokenAccount(tokenMint: .renBTCMint, isSimulation: false)
                .catch { error in
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
            isRenBTCWalletCreated: Bool,
            hasExplorerButton: Bool
        ) {
            self.navigationSubject = navigationSubject
            self.hasExplorerButton = hasExplorerButton

            super.init()

            if isRenBTCWalletCreated {
                createRenBTCSubject.accept(nil, state: .loaded)
            }

            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        func reload() {
            renVMService.reload()
        }

        func createRenBTCWallet() {
            createRenBTCSubject.reload()
        }
        
        func acceptConditionAndLoadAddress() {
            renVMService.acceptConditionAndLoadAddress()
        }

//        func acceptReceivingRenBTC() -> Completable {
            //            return handler.hasAssociatedTokenAccountBeenCreated(tokenMint: .renBTCMint)
            //                .catch {error in
            //                    if error.isEqualTo(SolanaSDK.Error.couldNotRetrieveAccountInfo) {
            //                        return .just(false)
            //                    }
            //                    throw error
            //                }
            //                .flatMapCompletable { [weak self] isRenBtcCreated in
            //                    guard let self = self else {return .error(SolanaSDK.Error.unknown)}
            //                    if isRenBtcCreated {
            //                        self.receiveBitcoinViewModel.acceptConditionAndLoadAddress()
            //                        self.switchToken(.btc)
            //                        return .empty()
            //                    }
            //                    return self.handler.createAssociatedTokenAccount(tokenMint: .renBTCMint, isSimulation: false)
            //                        .asCompletable()
            //                }
//        }

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

        func toggleIsReceivingRenBTC(isReceivingRenBTC: Bool) {
            isReceivingRenBTCSubject.accept(isReceivingRenBTC)
        }
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    func getStatus() -> Single<ReceiveTokenBitcoinViewModelStatus> {
        if isReceivingRentBTC && isConditionAccepted {
            return .just(.ready)
        }

        return rentBTCService
            .hasAssociatedTokenAccountBeenCreated()
            .flatMap { [weak self] hasAssociatedAccount -> Single<ReceiveTokenBitcoinViewModelStatus> in
                // Account has been created
                if hasAssociatedAccount { return .just(.needAcceptCondition) }

                guard let self = self else { return .just(.unknown(error: SolanaSDK.Error.other("RentBtc was deallocated"))) }
                // Account have to be created
                return self.rentBTCService
                    .isAssociatedAccountCreatable()
                    .map { isCreatable in
                        if isCreatable {
                            return .needCreateAccount
                        } else {
                            return .needTopUpAccount
                        }
                    }
            }
    }

    var isReceivingRentBTC: Bool { isReceivingRenBTCSubject.value }

    var isConditionAccepted: Bool { renVMService.isConditionAccepted }

    var isReceivingRenBTCDriver: Driver<Bool> {
        isReceivingRenBTCSubject.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        renVMService.isLoadingDriver
    }

    var errorDriver: Driver<String?> {
        renVMService.errorDriver
    }

    var renBTCWalletCreatingDriver: Driver<Loadable<String>> {
        createRenBTCSubject.asDriver()
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

    var minimumTransactionAmountDriver: Driver<Loadable<Double>> {
        renVMService.minimumTransactionAmountDriver
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

    @objc private func saveImageCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
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

    func reloadMinimumTransactionAmount() {
        renVMService.reloadMinimumTransactionAmount()
    }

    func showReceivingStatuses() {
        navigationSubject.accept(.showRenBTCReceivingStatus)
    }
}
