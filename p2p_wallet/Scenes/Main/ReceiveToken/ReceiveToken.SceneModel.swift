//
//  ReceiveToken.SceneModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol ReceiveSceneModel: BESceneModel {
    var tokenTypeDriver: Driver<ReceiveToken.TokenType> { get }
    var hasAddressesInfoDriver: Driver<Bool> { get }
    var hasHintViewOnTopDriver: Driver<Bool> { get }
    var addressesInfoIsOpenedDriver: Driver<Bool> { get }
    var showHideAddressesInfoButtonTapSubject: PublishRelay<Void> { get }
    var addressesHintIsHiddenDriver: Driver<Bool> { get }
    var hideAddressesHintSubject: PublishRelay<Void> { get }
    var tokenListAvailabilityDriver: Driver<Bool> { get }
    var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType { get }
    var receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType { get }
    var shouldShowChainsSwitcher: Bool { get }
    var tokenWallet: Wallet? { get }
    var navigation: Driver<ReceiveToken.NavigatableScene?> { get }

    func isRenBtcCreated() -> Bool
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func showSelectionNetwork()
    func copyDirectAddress()
    func copyMintAddress()
    func navigateToBuy()
}

extension ReceiveToken {
    class SceneModel: NSObject, ReceiveSceneModel {
        @Injected private var handler: AssociatedTokenAccountHandler
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationsService: NotificationService
        @Injected private var walletsRepository: WalletsRepository

        // MARK: - Properties

        private let disposeBag = DisposeBag()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType

        // MARK: - Subjects

        let showHideAddressesInfoButtonTapSubject = PublishRelay<Void>()
        let addressesHintIsHiddenSubject = BehaviorRelay<Bool>(value: false)
        let hideAddressesHintSubject = PublishRelay<Void>()
        private let navigationSubject = PublishRelay<NavigatableScene?>()
        private let tokenTypeSubject = BehaviorRelay<TokenType>(value: .solana)
        private let addressesInfoIsOpenedSubject = BehaviorRelay<Bool>(value: false)
        let tokenWallet: Wallet?
        private let canOpenTokensList: Bool
        let shouldShowChainsSwitcher: Bool
        private let screenCanHaveAddressesInfo: Bool
        private let screenCanHaveHint: Bool

        init(
            solanaPubkey: SolanaSDK.PublicKey,
            solanaTokenWallet: Wallet? = nil,
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
                hasExplorerButton: hasExplorerButton
            )

            super.init()

            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
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

        func switchToken(_ tokenType: ReceiveToken.TokenType) {
            tokenTypeSubject.accept(tokenType)
            if tokenType == .btc {
                receiveBitcoinViewModel.acceptConditionAndLoadAddress()
            }
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

        func isRenBtcCreated() -> Bool {
            walletsRepository.getWallets().contains(where: \.token.isRenBTC)
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

        func navigateToBuy() {
            navigationSubject.accept(.buy)
        }
    }
}
