//
//  ReceiveToken.SceneModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import OrcaSwapSwift
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol ReceiveSceneModel: BESceneModel {
    var tokenTypeDriver: Driver<ReceiveToken.TokenType> { get }
    var hasAddressesInfoDriver: Driver<Bool> { get }
    var hasHintViewOnTopDriver: Driver<Bool> { get }
    var toggleToBtc: Driver<Void> { get }
    var showBitcoinConfirmation: Driver<ReceiveToken.BitcoinConfirmScene.SceneType> { get }
    var showLoader: Driver<Bool> { get }
    var back: Driver<Void> { get }
    var showAlert: Driver<(String, String)> { get }
    var addressesInfoIsOpenedDriver: Driver<Bool> { get }
    var showHideAddressesInfoButtonTapSubject: PublishRelay<Void> { get }
    var addressesHintIsHiddenDriver: Driver<Bool> { get }
    var hideAddressesHintSubject: PublishRelay<Void> { get }
    var renBtcAction: PublishRelay<ReceiveToken.BitcoinConfirmScene.Action> { get }
    var tokenListAvailabilityDriver: Driver<Bool> { get }
    var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType { get }
    var receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType { get }
    var shouldShowChainsSwitcher: Bool { get }
    var tokenWallet: Wallet? { get }
    var navigation: Driver<ReceiveToken.NavigatableScene?> { get }

    func acceptReceivingRenBTC() -> Completable
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func showSelectionNetwork()
    func copyDirectAddress()
    func copyMintAddress()
    func tapOnBitcoin()
}

extension ReceiveToken {
    class SceneModel: NSObject, ReceiveSceneModel {
        @Injected private var handler: AssociatedTokenAccountHandler
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationsService: NotificationsServiceType
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var renBtcService: RentBTC.Service

        // MARK: - Properties

        private let disposeBag = DisposeBag()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType

        // MARK: - Subjects

        let showHideAddressesInfoButtonTapSubject = PublishRelay<Void>()
        let addressesHintIsHiddenSubject = BehaviorRelay<Bool>(value: false)
        let hideAddressesHintSubject = PublishRelay<Void>()
        let renBtcAction = PublishRelay<ReceiveToken.BitcoinConfirmScene.Action>()
        private let navigationSubject = PublishRelay<NavigatableScene?>()
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        private let addressesInfoIsOpenedSubject = BehaviorRelay<Bool>(value: false)
        private let showLoaderRelay = PublishRelay<Bool>()
        private let backRelay = PublishRelay<Void>()
        private let showAlertRelay = PublishRelay<(String, String)>()
        private let toggleToBtcRelay = PublishSubject<Void>()
        let tokenWallet: Wallet?
        private let canOpenTokensList: Bool
        let shouldShowChainsSwitcher: Bool
        private let screenCanHaveAddressesInfo: Bool
        private let screenCanHaveHint: Bool

        init(
            solanaPubkey: SolanaSDK.PublicKey,
            solanaTokenWallet: Wallet? = nil,
            isRenBTCWalletCreated: Bool,
            isOpeningFromToken: Bool = false
        ) {
            let isRenBTC = solanaTokenWallet?.token.isRenBTC ?? false
            let hasExplorerButton = !isOpeningFromToken
            tokenWallet = solanaTokenWallet
            canOpenTokensList = !isOpeningFromToken
            screenCanHaveAddressesInfo = isOpeningFromToken && solanaTokenWallet != nil
            screenCanHaveHint = isOpeningFromToken
            shouldShowChainsSwitcher = isOpeningFromToken ? isRenBTC : solanaTokenWallet?.isNativeSOL ?? true
            receiveSolanaViewModel = ReceiveToken.SolanaViewModel(
                solanaPubkey: solanaPubkey.base58EncodedString,
                solanaTokenWallet: solanaTokenWallet,
                navigationSubject: navigationSubject,
                hasExplorerButton: hasExplorerButton
            )

            receiveBitcoinViewModel = ReceiveToken.ReceiveBitcoinViewModel(
                navigationSubject: navigationSubject,
                isRenBTCWalletCreated: isRenBTCWalletCreated,
                hasExplorerButton: hasExplorerButton
            )

            super.init()

            bind()
        }

        var tokenTypeDriver: Driver<ReceiveToken.TokenType> { tokenTypeSubject.asDriver() }

        var hasAddressesInfoDriver: Driver<Bool> {
            tokenTypeDriver
                .map { [weak self] tokenType in
                    guard let self = self else { return false }

                    switch tokenType {
                    case .solana:
                        return self.screenCanHaveAddressesInfo
                    case .btc:
                        return false
                    }
                }
        }

        var addressesInfoIsOpenedDriver: Driver<Bool> {
            addressesInfoIsOpenedSubject.asDriver()
        }

        var addressesHintIsHiddenDriver: Driver<Bool> {
            addressesHintIsHiddenSubject.asDriver()
        }

        var tokenListAvailabilityDriver: Driver<Bool> {
            tokenTypeDriver
                .map { [weak self] in
                    switch $0 {
                    case .solana:
                        return self?.canOpenTokensList ?? false
                    case .btc:
                        return false
                    }
                }
        }

        var hasHintViewOnTopDriver: Driver<Bool> {
            tokenTypeDriver
                .map { [weak self] tokenType in
                    guard let self = self else { return false }

                    switch tokenType {
                    case .solana:
                        return self.screenCanHaveHint
                    case .btc:
                        return false
                    }
                }
        }

        private var toggleToBtcAccount: Observable<Bool> {
            Observable.combineLatest(
                receiveBitcoinViewModel.isReceivingRenBTCDriver.asObservable(),
                receiveBitcoinViewModel.conditionAcceptedDriver.asObservable(),
                toggleToBtcRelay
            )
                .map { isBtcCreated, accepted, _ in
                    isBtcCreated && accepted
                }
        }

        var toggleToBtc: Driver<Void> {
            toggleToBtcAccount.filter { $0 }.mapToVoid().asDriver()
        }

        typealias BitcoinSceneType = ReceiveToken.BitcoinConfirmScene.SceneType

        var showBitcoinConfirmation: Driver<BitcoinSceneType> {
            toggleToBtcAccount.filter { !$0 }
                .mapToVoid()
                .flatMap { [weak self] () -> Observable<BitcoinSceneType> in
                    guard let self = self else { return .empty() }

                    if self.renBtcService.hasAssociatedTokenAccountBeenCreated() {
                        return .just(.btcAccountCreated)
                    }

                    return Observable.asyncThrowing { [weak self] () -> BitcoinSceneType in
                        let isCreatable = try await self?.renBtcService.isAssociatedAccountCreatable() ?? false
                        return isCreatable ? .noBtcAccount : .noBtcAccountAndFundsForPay
                    }
                }
                .asDriver()
        }

        var showLoader: Driver<Bool> {
            Driver.merge(
                showLoaderRelay.asDriver(),
                toggleToBtc.map { false },
                showBitcoinConfirmation.map { _ in false }
            )
        }

        var back: Driver<Void> {
            backRelay.asDriver()
        }

        var showAlert: Driver<(String, String)> {
            showAlertRelay.asDriver()
        }

        func switchToken(_ tokenType: ReceiveToken.TokenType) {
            tokenTypeSubject.accept(tokenType)
        }

        func showSelectionNetwork() {
            navigationSubject.accept(.networkSelection)
        }

        func copyDirectAddress() {
            guard let address = tokenWallet?.pubkey else { return assertionFailure() }

            clipboardManager.copyToClipboard(address)
            showCopied()
        }

        func copyMintAddress() {
            guard let address = tokenWallet?.mintAddress else { return assertionFailure() }

            clipboardManager.copyToClipboard(address)
            showCopied()
        }

        func tapOnBitcoin() {
            showLoaderRelay.accept(true)
            toggleToBtcRelay.onNext(())
        }

        func acceptReceivingRenBTC() -> Completable {
            handler.hasAssociatedTokenAccountBeenCreated(tokenMint: .renBTCMint)
                .catch { error in
                    if error.isEqualTo(SolanaSDK.Error.couldNotRetrieveAccountInfo) {
                        return .just(false)
                    }
                    throw error
                }
                .flatMapCompletable { [weak self] isRenBtcCreated in
                    guard let self = self else { return .error(SolanaSDK.Error.unknown) }
                    if isRenBtcCreated {
                        self.receiveBitcoinViewModel.acceptConditionAndLoadAddress()
                        self.switchToken(.btc)
                        return .empty()
                    }
                    return self.handler.createAssociatedTokenAccount(tokenMint: .renBTCMint, isSimulation: false)
                        .asCompletable()
                }
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

            renBtcAction
                .subscribe(onNext: { [weak self] action in
                    guard let self = self else { return }

                    switch action {
                    case .iUnderstand:
                        self.showLoaderRelay.accept(true)
                        self.acceptReceivingRenBTC().subscribe(
                            onCompleted: { [weak self] in
                                guard let self = self else { return }
                                self.showLoaderRelay.accept(false)
                                self.backRelay.accept(())
                            },
                            onError: { [weak self] error in
                                guard let self = self else { return }
                                #if DEBUG
                                    debugPrint("Create renBTC error: \(error)")
                                #endif
                                self.showLoaderRelay.accept(false)
                                self.showAlertRelay.accept((
                                    L10n.error.uppercaseFirst,
                                    L10n.couldNotCreateRenBTCTokenPleaseTryAgainLater
                                ))
                            }
                        )
                            .disposed(by: self.disposeBag)
                    case .topUpAccount:
                        self.navigationSubject.accept(.showBuy)
                    case .shareSolanaAddress:
                        self.receiveSolanaViewModel.shareAction()
                    case .payAndContinue:
                        self.backRelay.accept(())
                    }
                })
                .disposed(by: disposeBag)
        }

        private func showCopied() {
            notificationsService.showInAppNotification(.done(L10n.copiedToClipboard))
        }
    }
}
