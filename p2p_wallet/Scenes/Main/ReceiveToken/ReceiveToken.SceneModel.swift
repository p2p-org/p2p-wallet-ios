//
//  ReceiveToken.SceneModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import Foundation
import Resolver
import Combine
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
    var shouldShowChainsSwitcher: Bool { get }
    var tokenWallet: Wallet? { get }
    var qrHint: NSAttributedString { get }
    var isDisabledRenBtc: Bool { get }
    var navigationPublisher: AnyPublisher<ReceiveToken.NavigatableScene?, Never> { get }

    func isRenBtcCreated() -> Bool
    func copyDirectAddress()
    func copyMintAddress()
    func navigateToBuy()
}

extension ReceiveToken {
    @MainActor
    class SceneModel: NSObject, ReceiveSceneModel, ObservableObject {
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var notificationsService: NotificationService
        @Injected private var walletsRepository: WalletsRepository

        // MARK: - Properties

        private var subscriptions = Set<AnyCancellable>()
        let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType

        // MARK: - Subjects

        let showHideAddressesInfoButtonTapSubject = PassthroughSubject<Void, Never>()
        @Published private var addressesHintIsHidden = false
        let hideAddressesHintSubject = PassthroughSubject<Void, Never>()
        private let navigationSubject = PassthroughSubject<NavigatableScene?, Never>()
        @Published private var tokenType: TokenType = .solana
        @Published private var addressesInfoIsOpened: Bool = false
        let tokenWallet: Wallet?
        let qrHint: NSAttributedString
        let isDisabledRenBtc: Bool
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
            let symbol = solanaTokenWallet?.token.symbol ?? ""

            isDisabledRenBtc = !available(.receiveRenBtcEnabled)

            let highlightedText = L10n.receive(symbol)
            let fullText = L10n.youCanReceiveByProvidingThisAddressQRCodeOrUsername(symbol)
            let normalFont = UIFont.systemFont(ofSize: 15, weight: .regular)
            let highlightedFont = UIFont.systemFont(ofSize: 15, weight: .bold)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.17
            paragraphStyle.alignment = .center
            let attributedText = NSMutableAttributedString(
                string: fullText,
                attributes: [
                    .font: normalFont,
                    .kern: -0.24,
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: UIColor.textBlack,
                ]
            )
            let highlightedRange = (attributedText.string as NSString)
                .range(of: highlightedText, options: .caseInsensitive)
            attributedText.addAttribute(.font, value: highlightedFont, range: highlightedRange)
            qrHint = attributedText

            tokenWallet = solanaTokenWallet

            canOpenTokensList = !isOpeningFromToken
            screenCanHaveAddressesInfo = isOpeningFromToken && solanaTokenWallet != nil
            screenCanHaveHint = isOpeningFromToken
            if isDisabledRenBtc && isRenBTC {
                shouldShowChainsSwitcher = false
            } else {
                shouldShowChainsSwitcher = isOpeningFromToken ? isRenBTC : solanaTokenWallet?.isNativeSOL ?? true
            }
            receiveSolanaViewModel = ReceiveToken.SolanaViewModel(
                solanaPubkey: solanaPubkey.base58EncodedString,
                solanaTokenWallet: solanaTokenWallet,
                navigationSubject: navigationSubject,
                hasExplorerButton: hasExplorerButton
            )

            super.init()

            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        var tokenTypePublisher: AnyPublisher<ReceiveToken.TokenType, Never> { $tokenType.receive(on: DispatchQueue.main).eraseToAnyPublisher() }

        var hasAddressesInfoPublisher: AnyPublisher<Bool, Never> {
            tokenTypePublisher
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
            $addressesInfoIsOpened.receive(on: DispatchQueue.main).eraseToAnyPublisher()
        }

        var addressesHintIsHiddenPublisher: AnyPublisher<Bool, Never> {
            $addressesHintIsHidden.receive(on: DispatchQueue.main).eraseToAnyPublisher()
        }

        var tokenListAvailabilityPublisher: AnyPublisher<Bool, Never> {
            tokenTypePublisher
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
            tokenTypePublisher
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

        var navigationPublisher: AnyPublisher<NavigatableScene?, Never> {
            navigationSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
        }

        private func bind() {
            showHideAddressesInfoButtonTapSubject
                .sink(receiveValue: { [weak self] in
                    self?.addressesInfoIsOpened.toggle()
                })
                .store(in: &subscriptions)

            hideAddressesHintSubject
                .sink(receiveValue: { [weak self] in
                    self?.addressesHintIsHidden = true
                })
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
