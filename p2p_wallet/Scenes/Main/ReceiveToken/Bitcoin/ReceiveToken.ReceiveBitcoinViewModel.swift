//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import RenVMSwift
import Resolver
import RxCocoa
import RxSwift

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

    func reload()
    func reloadMinimumTransactionAmount()
    func getSessionEndDate() -> Date?
    func createRenBTCWallet()
    func acceptConditionAndLoadAddress()
    func toggleIsReceivingRenBTC(isReceivingRenBTC: Bool)
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

        @Injected private var renVMService: RenVMLockAndMintServiceType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var imageSaver: ImageSaverType
        @Injected var notificationsService: NotificationsServiceType
        private let navigationSubject: PublishRelay<NavigatableScene?>
        @Injected private var associatedTokenAccountHandler: AssociatedTokenAccountHandler

        // MARK: - Subjects

        private let isReceivingRenBTCSubject = BehaviorRelay<Bool>(value: true)
        private lazy var createRenBTCSubject: LoadableRelay<String> = .init(
            request: associatedTokenAccountHandler
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
        notificationsService.showInAppNotification(.done(L10n.addressCopiedToClipboard))
        analyticsManager.log(event: .receiveAddressCopied)
    }

    func share(image: UIImage) {
        analyticsManager.log(event: .receiveAddressShare)
        navigationSubject.accept(
            .share(address: renVMService.getCurrentAddress() ?? "", qrCode: image)
        )
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

    func showBTCAddressInExplorer() {
        guard let address = renVMService.getCurrentAddress() else { return }
        analyticsManager.log(event: .receiveViewingExplorer)
        navigationSubject.accept(.showBTCExplorer(address: address))
    }

    func reloadMinimumTransactionAmount() {
        renVMService.reloadMinimumTransactionAmount()
    }

    func showReceivingStatuses() {
        navigationSubject.accept(.showRenBTCReceivingStatus)
    }
}
