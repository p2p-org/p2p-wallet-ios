//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import AnalyticsManager
import RenVMSwift
import Resolver
import RxCocoa
import RxSwift

protocol ReceiveTokenBitcoinViewModelType: AnyObject {
    var addressDriver: Driver<String?> { get }
    var timerSignal: Signal<Void> { get }
    var processingTxsDriver: Driver<[LockAndMint.ProcessingTx]> { get }
    var hasExplorerButton: Bool { get }
    var sessionEndDate: Date? { get }

    func acceptConditionAndLoadAddress()
    func showReceivingStatuses()
    func copyToClipboard()
    func share(image: UIImage)
    func saveAction(image: UIImage)
    func showBTCAddressInExplorer()
}

extension ReceiveToken {
    class ReceiveBitcoinViewModel {
        // MARK: - Constants

        private let disposeBag = DisposeBag()
        let hasExplorerButton: Bool

        // MARK: - Dependencies

        @Injected private var persistentStore: LockAndMintServicePersistentStore
        @Injected private var lockAndMintService: LockAndMintService
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var imageSaver: ImageSaverType
        @Injected var notificationsService: NotificationService

        // MARK: - Subjects

        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        private let timerSubject = PublishRelay<Void>()
        private let navigationSubject: PublishRelay<NavigatableScene?>
        private let addressSubject = BehaviorRelay<String?>(value: nil)
        private let processingTransactionsSubject = BehaviorRelay<[LockAndMint.ProcessingTx]>(value: [])

        // MARK: - Properties

        private(set) var sessionEndDate: Date?

        // MARK: - Initializers

        init(
            navigationSubject: PublishRelay<NavigatableScene?>,
            hasExplorerButton: Bool
        ) {
            self.navigationSubject = navigationSubject
            self.hasExplorerButton = hasExplorerButton

            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        func acceptConditionAndLoadAddress() {
            Task {
                let session = await persistentStore.session
                if session == nil || session?.isValid == false {
                    try await lockAndMintService.createSession()
                }
            }
        }

        private func bind() {
            // timer
            Timer.observable(seconds: 1)
                .bind(to: timerSubject)
                .disposed(by: disposeBag)

            timerSubject
                .withLatestFrom(
                    Single.async {
                        await self.persistentStore.session?.endAt
                    }
                )
                .subscribe(onNext: { [weak self] endAt in
                    guard let endAt = endAt else { return }
                    if Date() >= endAt {
                        Task { [weak self] in
                            try await self?.lockAndMintService.expireCurrentSession()
                        }
                    }
                })
                .disposed(by: disposeBag)

            // listen to lockAndMintService
            lockAndMintService.delegate = self

            if lockAndMintService.isLoading {
                isLoadingSubject.accept(true)
            }

            Task {
                guard let address = await persistentStore.gatewayAddress else { return }
                await MainActor.run { [weak self] in
                    self?.addressSubject.accept(address)
                }
            }
        }
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: LockAndMintServiceDelegate {
    func lockAndMintServiceWillStartLoading(_: LockAndMintService) {
        isLoadingSubject.accept(true)
    }

    func lockAndMintService(_: LockAndMintService, didLoadWithGatewayAddress gatewayAddress: String) {
        addressSubject.accept(gatewayAddress)
        Task {
            let endAt = await persistentStore.session?.endAt
            await MainActor.run {
                sessionEndDate = endAt
            }
        }
    }

    func lockAndMintService(_: LockAndMintService, didFailToLoadWithError _: Error) {
        sessionEndDate = nil
    }

    func lockAndMintService(
        _: LockAndMintService,
        didUpdateTransactions processingTransactions: [LockAndMint.ProcessingTx]
    ) {
        processingTransactionsSubject.accept(processingTransactions)
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    var addressDriver: Driver<String?> {
        addressSubject.asDriver()
    }

    var timerSignal: Signal<Void> {
        timerSubject.asSignal()
    }

    var processingTxsDriver: Driver<[LockAndMint.ProcessingTx]> {
        processingTransactionsSubject.asDriver()
    }

    func copyToClipboard() {
        Task {
            guard let address = await persistentStore.gatewayAddress else { return }
            await MainActor.run {
                clipboardManager.copyToClipboard(address)
                notificationsService.showInAppNotification(.done(L10n.addressCopiedToClipboard))
                analyticsManager.log(event: AmplitudeEvent.receiveAddressCopied)
            }
        }
    }

    func share(image: UIImage) {
        Task {
            guard let address = await persistentStore.gatewayAddress else { return }
            await MainActor.run {
                analyticsManager.log(event: AmplitudeEvent.receiveAddressShare)
                navigationSubject.accept(
                    .share(address: address, qrCode: image)
                )
            }
        }
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
                    self?.navigationSubject.accept(.showPhotoLibraryUnavailable)
                case .restrictedRightNow:
                    break
                case let .unknown(error):
                    self?.notificationsService.showInAppNotification(.error(error))
                }
            }
        }
    }

    func showBTCAddressInExplorer() {
        Task {
            guard let address = await persistentStore.gatewayAddress else { return }
            await MainActor.run {
                analyticsManager.log(event: AmplitudeEvent.receiveViewingExplorer)
                navigationSubject.accept(.showBTCExplorer(address: address))
            }
        }
    }

    func showReceivingStatuses() {
        navigationSubject.accept(.showRenBTCReceivingStatus)
    }
}
