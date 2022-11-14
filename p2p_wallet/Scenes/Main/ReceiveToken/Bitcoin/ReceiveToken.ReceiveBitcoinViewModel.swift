//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import AnalyticsManager
import RenVMSwift
import Resolver
import SolanaSwift
import Combine

extension ReceiveToken {
    @MainActor
    class ReceiveBitcoinViewModel: ObservableObject {
        // MARK: - Constants

        private var subscriptions = [AnyCancellable]()
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

        @Published private var state = LockAndMintServiceState.initializing
        var statePublisher: AnyPublisher<LockAndMintServiceState, Never> {
            $state
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        var gatewayAddressPublisher: AnyPublisher<String?, Never> {
            $state
                .map {[weak self] _ in try? self?.lockAndMintService.getCurrentGatewayAddress()}
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        var minimumTransactionAmountPublisher: AnyPublisher<Double, Never> {
            $state.map {($0.estimatedTransctionFee?.convertToBalance(decimals: Token.renBTC.decimals) ?? 0) * 2}
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        @Published private var processingTransactions = [LockAndMint.ProcessingTx]()
        var processingTransactionsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> {
            $processingTransactions
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        // Timer
        let timerPublisher = Timer.publish(every: 1, on: RunLoop.main, in: .default)
            .eraseToAnyPublisher()
        
        // Navigation
        private let navigationSubject = PassthroughSubject<NavigatableScene?, Never>()
        var navigationPublisher: AnyPublisher<NavigatableScene?, Never> {
            navigationSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
        }

        // MARK: - Properties

        private(set) var sessionEndDate: Date?

        // MARK: - Initializers

        init(hasExplorerButton: Bool) {
            self.hasExplorerButton = hasExplorerButton
            bind()
            Task {
                await updateSessionEndDate()
            }
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        // MARK: - Binding
        
        private func bind() {
            // timer
            timerPublisher
                .asyncMap { [weak self] _ -> Date? in
                    guard let self = self else {return nil}
                    return await self.persistentStore.session?.endAt
                }
                .sinkAsync { [weak self] endAt in
                    guard let endAt = endAt else { return }
                    if Date() >= endAt {
                        Task { [weak self] in
                            try await self?.lockAndMintService.expireCurrentSession()
                        }
                    }
                }
                .store(in: &subscriptions)

            // listen to lockAndMintService
            lockAndMintService.statePublisher
                .receive(on: RunLoop.main)
                .assign(to: \.state, on: self)
                .store(in: &subscriptions)
            
            lockAndMintService.processingTxsPublisher
                .receive(on: RunLoop.main)
                .assign(to: \.processingTransactions, on: self)
                .store(in: &subscriptions)
        }

        // MARK: - Actions
        
        func acceptConditionAndLoadAddress() {
            Task {
                let session = await persistentStore.session
                if session == nil || session?.isValid == false {
                    try await lockAndMintService.createSession(endAt: Calendar.current.date(byAdding: .hour, value: 40, to: Date()))
                }
                await updateSessionEndDate()
            }
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
        
        // MARK: - Helpers
        
        private func updateSessionEndDate() async {
            let endAt = await persistentStore.session?.endAt
            await MainActor.run {
                sessionEndDate = endAt
            }
        }
    }
}
