//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import AnalyticsManager
import Combine
import RenVMSwift
import SolanaSwift
import Resolver

protocol ReceiveTokenBitcoinViewModelType: AnyObject {
    var addressPublisher: AnyPublisher<String?, Never> { get }
    var timerPublisher: AnyPublisher<Void, Never> { get }
    var processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> { get }
    var minimumTransactionAmountPublisher: AnyPublisher<Double?, Never> { get }
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
    class ReceiveBitcoinViewModel: BaseViewModel {
        // MARK: - Constants

        let hasExplorerButton: Bool

        // MARK: - Dependencies

        @Injected private var persistentStore: LockAndMintServicePersistentStore
        @Injected private var lockAndMintService: LockAndMintService
        @Injected private var renVMRpcClient: RenVMRpcClientType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var imageSaver: ImageSaverType
        @Injected var notificationsService: NotificationService

        // MARK: - Subjects

        @Published private var isLoading = false
        private let timerSubject = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
        private let navigationSubject: PassthroughSubject<NavigatableScene?, Never>
        @Published private var address: String?
        @Published private var processingTransactions = [LockAndMint.ProcessingTx]()
        private let minimumTransactionAmountSubject = PassthroughSubject<Double?, Never>()

        // MARK: - Properties

        private(set) var sessionEndDate: Date?

        // MARK: - Initializers

        init(
            navigationSubject: PassthroughSubject<NavigatableScene?, Never>,
            hasExplorerButton: Bool
        ) {
            self.navigationSubject = navigationSubject
            self.hasExplorerButton = hasExplorerButton
            super.init()
            Task { await bind() }
        }

        func acceptConditionAndLoadAddress() {
            Task {
                let session = await persistentStore.session
                if session == nil || session?.isValid == false {
                    try await lockAndMintService.createSession(endAt: Calendar.current.date(byAdding: .hour, value: 40, to: Date()))
                } else {
                    await updateSessionEndDate()
                }
            }
        }

        private func bind() async {
            // timer
            timerPublisher
                .withLatestFrom(
                    Just(Date()).asyncMap { _ in
                        await self.persistentStore.session?.endAt
                    }
                    .eraseToAnyPublisher()
                )
                .sink { [weak self] endAt in
                    guard let endAt = endAt else { return }
                    if Date() >= endAt {
                        Task { [weak self] in
                            try await self?.lockAndMintService.expireCurrentSession()
                        }
                    }
                }
                .store(in: &subscriptions)

            // listen to lockAndMintService
            await MainActor.run { [weak self] in
                self?.lockAndMintService.delegate = self
            }

            if lockAndMintService.isLoading {
                await MainActor.run { [weak self] in
                    self?.isLoading = true
                }
            }

            guard let address = await persistentStore.gatewayAddress else { return }
            await MainActor.run { [weak self] in
                self?.address = address
            }
            
            let fee = try? await renVMRpcClient.estimateTransactionFee()?
                .convertToBalance(decimals: Token.renBTC.decimals)
            await MainActor.run { [weak self] in
                self?.minimumTransactionAmountSubject.send(fee * 2)
            }
        }
        
        private func updateSessionEndDate() async {
            let endAt = await persistentStore.session?.endAt
            await MainActor.run {
                sessionEndDate = endAt
            }
        }
    }
}

// MARK: - LockAndMintServiceDelegate

extension ReceiveToken.ReceiveBitcoinViewModel: LockAndMintServiceDelegate {
    @MainActor func lockAndMintServiceWillStartLoading(_: LockAndMintService) {
        isLoading = true
    }

    @MainActor func lockAndMintService(_: LockAndMintService, didLoadWithGatewayAddress gatewayAddress: String) {
        address = gatewayAddress
        Task {
            await updateSessionEndDate()
        }
    }

    @MainActor func lockAndMintService(_: LockAndMintService, didFailToLoadWithError _: Error) {
        sessionEndDate = nil
    }

    @MainActor func lockAndMintService(
        _: LockAndMintService,
        didUpdateTransactions processingTransactions: [LockAndMint.ProcessingTx]
    ) {
        self.processingTransactions = processingTransactions
    }
}

// MARK: - ReceiveTokenBitcoinViewModelType

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    var addressPublisher: AnyPublisher<String?, Never> {
        $address.eraseToAnyPublisher()
    }

    var timerPublisher: AnyPublisher<Void, Never> {
        timerSubject.map { _ in () }.eraseToAnyPublisher()
    }
    
    var minimumTransactionAmountPublisher: AnyPublisher<Double?, Never> {
        minimumTransactionAmountSubject.eraseToAnyPublisher()
    }

    var processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> {
        $processingTransactions.eraseToAnyPublisher()
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
                navigationSubject.send(
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
                    self?.navigationSubject.send(.showPhotoLibraryUnavailable)
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
                navigationSubject.send(.showBTCExplorer(address: address))
            }
        }
    }

    func showReceivingStatuses() {
        navigationSubject.send(.showRenBTCReceivingStatus)
    }
}
