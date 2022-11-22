//
//  ReceiveToken.SceneModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Combine
import Foundation
import Resolver
import SolanaSwift

@MainActor
protocol ReceiveSceneModel: BESceneModel {
    var tokenTypePublisher: AnyPublisher<ReceiveToken.TokenType, Never> { get }
    var hasAddressesInfoPublisher: AnyPublisher<Bool, Never> { get }
    var hasHintViewOnTopPublisher: AnyPublisher<Bool, Never> { get }
    var addressesInfoIsOpenedPublisher: AnyPublisher<Bool, Never> { get }
    var showHideAddressesInfoButtonTapSubject: PassthroughSubject<Void, Never> { get }
    var addressesHintIsHiddenPublisher: AnyPublisher<Bool, Never> { get }
    var hideAddressesHintSubject: PassthroughSubject<Void, Never> { get }
    var tokenListAvailabilityPublisher: AnyPublisher<Bool, Never> { get }
    var receiveSolanaViewModel: ReceiveTokenSolanaViewModelType { get }
    var receiveBitcoinViewModel: ReceiveToken.ReceiveBitcoinViewModel { get }
    var shouldShowChainsSwitcher: Bool { get }
    var tokenWallet: Wallet? { get }
    var navigation: AnyPublisher<ReceiveToken.NavigatableScene?, Never> { get }

    func isRenBtcCreated() -> Bool
    func switchToken(_ tokenType: ReceiveToken.TokenType)
    func showSelectionNetwork()
    func copyDirectAddress()
    func copyMintAddress()
    func navigateToBuy()
}

extension ReceiveToken {
    @MainActor
    class SceneModel: NSObject, ReceiveSceneModel {
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationsService: NotificationService
        @Injected private var walletsRepository: WalletsRepository

        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        let receiveBitcoinViewModel: ReceiveToken.ReceiveBitcoinViewModel

        // MARK: - Subjects

        let showHideAddressesInfoButtonTapSubject = PassthroughSubject<Void, Never>()
        @Published var isAddressesHintHidden = false
        let hideAddressesHintSubject = PassthroughSubject<Void, Never>()
        private let navigationSubject = PassthroughSubject<NavigatableScene?, Never>()
        @Published private var tokenType = TokenType.solana
        @Published private var isAddressesInfoOpened = false
        let tokenWallet: Wallet?
        private let canOpenTokensList: Bool
        let shouldShowChainsSwitcher: Bool
        private let screenCanHaveAddressesInfo: Bool
        private let screenCanHaveHint: Bool

        init(
            solanaPubkey: PublicKey,
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
                hasExplorerButton: hasExplorerButton
            )

            super.init()

            bind()
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }

        var tokenTypePublisher: AnyPublisher<ReceiveToken.TokenType, Never> { $tokenType.eraseToAnyPublisher() }

        var hasAddressesInfoPublisher: AnyPublisher<Bool, Never> {
            $tokenType
                .map { [weak self] tokenType in
                    guard let self = self else { return false }

                    switch tokenType {
                    case .solana:
                        return self.screenCanHaveAddressesInfo
                    case .btc:
                        return false
                    }
                }
                .eraseToAnyPublisher()
        }

        var addressesInfoIsOpenedPublisher: AnyPublisher<Bool, Never> {
            $isAddressesInfoOpened.eraseToAnyPublisher()
        }

        var addressesHintIsHiddenPublisher: AnyPublisher<Bool, Never> {
            $isAddressesHintHidden.eraseToAnyPublisher()
        }

        var tokenListAvailabilityPublisher: AnyPublisher<Bool, Never> {
            $tokenType
                .map { [weak self] in
                    switch $0 {
                    case .solana:
                        return self?.canOpenTokensList ?? false
                    case .btc:
                        return false
                    }
                }
                .eraseToAnyPublisher()
        }

        var hasHintViewOnTopPublisher: AnyPublisher<Bool, Never> {
            $tokenType
                .map { [weak self] tokenType in
                    guard let self = self else { return false }

                    switch tokenType {
                    case .solana:
                        return self.screenCanHaveHint
                    case .btc:
                        return false
                    }
                }
                .eraseToAnyPublisher()
        }

        func switchToken(_ tokenType: ReceiveToken.TokenType) {
            self.tokenType = tokenType
            if tokenType == .btc {
                receiveBitcoinViewModel.acceptConditionAndLoadAddress()
            }
        }

        func showSelectionNetwork() {
            navigationSubject.send(.networkSelection)
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

        var navigation: AnyPublisher<NavigatableScene?, Never> {
            navigationSubject.eraseToAnyPublisher()
        }

        private func bind() {
            showHideAddressesInfoButtonTapSubject
                .sink { [weak self] in
                    self?.isAddressesInfoOpened = !(self?.isAddressesInfoOpened ?? true)
                }
                .store(in: &subscriptions)

            hideAddressesHintSubject
                .sink { [weak addressesHintIsHiddenSubject] in
                    guard let addressesHintIsHiddenSubject = addressesHintIsHiddenSubject else { return }
                    addressesHintIsHiddenSubject.accept(true)
                }
                .store(in: &subscriptions)

            receiveBitcoinViewModel
                .navigationPublisher
                .assign(to: navigationSubject, on: self)
                .store(in: &subscriptions)
        }

        private func showCopied() {
            notificationsService.showInAppNotification(.done(L10n.copiedToClipboard))
        }

        func navigateToBuy() {
            navigationSubject.send(.buy)
        }
    }
}
