//
//  ReceiveToken.SceneModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReceiveSceneModel: BESceneModel {
    var tokenTypeDriver: Driver<ReceiveToken.TokenType> { get }
    var hasAddressesInfoDriver: Driver<Bool> { get }
    var addressesInfoIsOpenedDriver: Driver<Bool> { get }
    var showHideAddressesInfoButtonTapSubject: PublishRelay<Void> { get }
    var addressesHintIsHiddenDriver: Driver<Bool> { get }
    var hideAddressesHintSubject: PublishRelay<Void> { get }
    var updateLayoutDriver: Driver<Void> { get }
    var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType { get }
    var receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType { get }
    var shouldShowChainsSwitcher: Bool { get }
    var tokenWallet: Wallet? { get }
    var hasAddressesInfo: Bool { get }
    var hasHintViewOnTop: Bool { get }
    var navigation: Driver<ReceiveToken.NavigatableScene?> { get }

    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func copyToClipboard(address: String, logEvent: AnalyticsEvent)
    func showSelectionNetwork()
    func copyDirectAddress()
    func copyMintAddress()
}

extension ReceiveToken {
    class SceneModel: NSObject, ReceiveSceneModel {
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationsService: NotificationsServiceType

        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType

        // MARK: - Subjects
        let showHideAddressesInfoButtonTapSubject = PublishRelay<Void>()
        private let navigationSubject = PublishRelay<NavigatableScene?>()
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        private let addressesInfoIsOpenedSubject = BehaviorRelay<Bool>(value: false)
        let tokenWallet: Wallet?

        let hasAddressesInfo: Bool
        let hasHintViewOnTop: Bool
        let addressesHintIsHiddenSubject = BehaviorRelay<Bool>(value: false)
        let hideAddressesHintSubject = PublishRelay<Void>()

        init(
            solanaPubkey: SolanaSDK.PublicKey,
            solanaTokenWallet: Wallet? = nil,
            isRenBTCWalletCreated: Bool,
            isOpeningFromToken: Bool = false
        ) {
            self.tokenWallet = solanaTokenWallet
            self.hasAddressesInfo = isOpeningFromToken && solanaTokenWallet != nil
            self.hasHintViewOnTop = isOpeningFromToken

            receiveSolanaViewModel = ReceiveToken.SolanaViewModel(
                solanaPubkey: solanaPubkey.base58EncodedString,
                solanaTokenWallet: solanaTokenWallet,
                navigationSubject: navigationSubject
            )
            
            receiveBitcoinViewModel = ReceiveToken.ReceiveBitcoinViewModel(
                navigationSubject: navigationSubject,
                isRenBTCWalletCreated: isRenBTCWalletCreated
            )
            
            super.init()
            
            if let token = solanaTokenWallet?.token,
               token.isRenBTC {
                tokenTypeSubject.accept(.btc)
            }

            bind()
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        var tokenTypeDriver: Driver<ReceiveToken.TokenType> { tokenTypeSubject.asDriver() }
        
        var updateLayoutDriver: Driver<Void> {
            Driver.combineLatest(
                    tokenTypeDriver,
                    receiveBitcoinViewModel.isReceivingRenBTCDriver,
                    receiveBitcoinViewModel.renBTCWalletCreatingDriver,
                    receiveBitcoinViewModel.conditionAcceptedDriver,
                    receiveBitcoinViewModel.addressDriver,
                    receiveBitcoinViewModel.processingTxsDriver
                )
                .map { _ in () }.asDriver()
        }

        var hasAddressesInfoDriver: Driver<Bool> {
            .just(hasAddressesInfo)
        }

        var addressesInfoIsOpenedDriver: Driver<Bool> {
            addressesInfoIsOpenedSubject.asDriver()
        }

        var addressesHintIsHiddenDriver: Driver<Bool> {
            addressesHintIsHiddenSubject.asDriver()
        }

        func switchToken(_ tokenType: ReceiveToken.TokenType) {
            tokenTypeSubject.accept(tokenType)
        }
        
        func copyToClipboard(address: String, logEvent: AnalyticsEvent) {
            clipboardManager.copyToClipboard(address)
            analyticsManager.log(event: logEvent)
        }
        
        var shouldShowChainsSwitcher: Bool {
            receiveSolanaViewModel.tokenWallet == nil
        }
        
        func showSelectionNetwork() {
            navigationSubject.accept(.networkSelection)
        }

        func copyDirectAddress() {
            guard let address = receiveSolanaViewModel.tokenWallet?.pubkey else { return assertionFailure() }

            clipboardManager.copyToClipboard(address)
            showCopied()
        }

        func copyMintAddress() {
            guard let address = receiveSolanaViewModel.tokenWallet?.mintAddress else { return assertionFailure() }

            clipboardManager.copyToClipboard(address)
            showCopied()
        }
        
        var navigation: Driver<NavigatableScene?> { navigationSubject.asDriver(onErrorDriveWith: Driver.empty()) }

        private func bind() {
            showHideAddressesInfoButtonTapSubject
                .subscribe(onNext: { [weak addressesInfoIsOpenedSubject] in
                    guard let addressesInfoIsOpenedSubject = addressesInfoIsOpenedSubject else { return }
                    addressesInfoIsOpenedSubject.accept(!addressesInfoIsOpenedSubject.value)
                })
                .disposed(by: disposeBag)

            hideAddressesHintSubject
                .subscribe(onNext: { [weak addressesHintIsHiddenSubject] in
                    guard let addressesHintIsHiddenSubject = addressesHintIsHiddenSubject else { return }
                    addressesHintIsHiddenSubject.accept(true)
                })
                .disposed(by: disposeBag)
        }

        private func showCopied() {
            notificationsService.showInAppNotification(.done(L10n.copiedToClipboard))
        }
    }
}
