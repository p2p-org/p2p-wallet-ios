//
//  SendToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import AnalyticsManager
import Combine
import FeeRelayerSwift
import Foundation
import Resolver
import SolanaSwift

protocol SendTokenViewModelType: SendTokenRecipientAndNetworkHandler, SendTokenTokenAndAmountHandler,
    SendTokenSelectNetworkViewModelType
{
    // navigatableScene
    var navigatableScenePublisher: AnyPublisher<SendToken.NavigatableScene?, Never> { get }
    func setNavigatableScene(_ scene: SendToken.NavigatableScene?)
    
    // loadingState
    var loadingStatePublisher: AnyPublisher<LoadableState, Never> { get }
    
    var relayMethod: SendTokenRelayMethod { get }
    var canGoBack: Bool { get }

    func getPrice(for symbol: String) -> Double
    func getPrices(for symbols: [String]) -> [String: Double]
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSelectedNetwork() -> SendToken.Network
    func getSelectedAmount() -> Double?
    func getFreeTransactionFeeLimit() async throws -> UsageStatus

    func reload() async
    func navigate(to scene: SendToken.NavigatableScene)
    func chooseWallet(_ wallet: Wallet)
    func cleanAllFields()

    func shouldShowConfirmAlert() -> Bool
    func closeConfirmAlert()

    func authenticateAndSend()
}

extension SendToken {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected private var authenticationHandler: AuthenticationHandlerType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        let sendService: SendServiceType

        // MARK: - Properties

        var subscriptions = [AnyCancellable]()
        let relayMethod: SendTokenRelayMethod
        let canGoBack: Bool

        // MARK: - Subject

        @Published var navigatableScene: NavigatableScene?
        @Published private var wallet: Wallet?
        @Published private var amount: Double?
        @Published var recipient: Recipient?
        @Published var network = Network.solana
        @Published private var loadingState = LoadableState.notRequested
        @Published var payingWallet: Wallet?
        let feeInfoSubject = LoadableRelay<SendToken.FeeInfo>(
            request: {
                .init(feeAmount: .zero, feeAmountInSOL: .zero, hasAvailableWalletToPayFee: nil)
            }
        )

        // MARK: - Initializers

        init(
            walletPubkey: String?,
            destinationAddress _: String?,
            relayMethod: SendTokenRelayMethod,
            canGoBack: Bool = true
        ) {
            self.relayMethod = relayMethod
            self.canGoBack = canGoBack
            sendService = Resolver.resolve(args: relayMethod)

            // accept initial values
            if let pubkey = walletPubkey,
               let selectableWallet = walletsRepository.getWallets()
                   .first(where: { $0.pubkey == pubkey }) ?? walletsRepository.nativeWallet
            {
                wallet = selectableWallet
            } else {
                wallet = walletsRepository.nativeWallet
            }

            bind()
            Task {
                await reload()
            }
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }

        func bind() {
            bindFees()

            // update wallet after sending
            walletsRepository.dataPublisher
                .dropFirst()
                .withLatestFrom($wallet, resultSelector: { ($0, $1) })
                .sink { [weak self] wallets, myWallet in
                    guard let self = self else { return }
                    if let wallet = wallets.first(where: { $0.pubkey == myWallet?.pubkey }),
                       wallet.lamports != myWallet?.lamports
                    {
                        self.wallet = wallet
                    }
                }
                .store(in: &subscriptions)
        }

        func reload() async {
            loadingState = .loading
            do {
                _ = try await(
                    sendService.load(),
                    walletsRepository.statePublisher
                        .filter { $0 == .loaded }
                        .prefix(1)
                        .map { _ in () }
                        .eraseToAnyPublisher()
                        .async()
                )

                loadingState = .loaded
                if wallet == nil {
                    wallet = walletsRepository.getWallets().first(where: { $0.isNativeSOL })
                }
                if let payingWallet = walletsRepository.getWallets()
                    .first(where: { $0.mintAddress == Defaults.payingTokenMint })
                {
                    self.payingWallet = payingWallet
                }
            } catch {
                loadingState = .error(error.readableDescription)
            }
        }

        private func send() {
            guard let wallet = wallet,
                  var amount = amount,
                  let receiver = recipient
            else { return }

            // modify amount if using source wallet as paying wallet
            if let totalFee = feeInfoSubject.value?.feeAmount,
               totalFee.total > 0,
               payingWallet?.pubkey == wallet.pubkey
            {
                let feeAmount = totalFee.total.convertToBalance(decimals: payingWallet?.token.decimals)
                if amount + feeAmount > wallet.amount {
                    amount -= feeAmount
                }
            }

            analyticsManager.log(
                event: .sendSendClick(
                    tokenTicker: wallet.token.symbol,
                    sum: amount
                )
            )

            navigatableScene = .processTransaction(
                ProcessTransaction.SendTransaction(
                    sendService: sendService,
                    network: network,
                    sender: wallet,
                    receiver: receiver,
                    authority: walletsRepository.nativeWallet?.pubkey,
                    amount: amount.toLamport(decimals: wallet.token.decimals),
                    payingFeeWallet: payingWallet,
                    feeInSOL: feeInfoSubject.value?.feeAmountInSOL.total ?? 0,
                    feeInToken: feeInfoSubject.value?.feeAmount,
                    isSimulation: false
                )
            )
        }
    }
}

extension SendToken.ViewModel: SendTokenViewModelType {
    // MARK: - navigatableScene
    
    func setNavigatableScene(_ scene: SendToken.NavigatableScene?) {
        navigatableScene = scene
    }
    
    var navigatableScenePublisher: AnyPublisher<SendToken.NavigatableScene?, Never> {
        $navigatableScene.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    // MARK: - loadingState
    
    var loadingStatePublisher: AnyPublisher<LoadableState, Never> {
        $loadingState.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    // MARK: - SendTokenRecipientAndNetworkHandler
    func setRecipient(_ recipient: SendToken.Recipient?) {
        self.recipient = recipient
    }
    
    var recipientPublisher: AnyPublisher<SendToken.Recipient?, Never> {
        $recipient.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    func setNetwork(_ network: SendToken.Network?) {
        guard let network = network else {
            return
        }
        self.network = network
    }
    
    var networkPublisher: AnyPublisher<SendToken.Network, Never> {
        $network.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    func setPayingWallet(_ payingWallet: Wallet?) {
        self.payingWallet = payingWallet
    }
    
    var payingWalletPublisher: AnyPublisher<Wallet?, Never> {
        $payingWallet.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    

    func getSelectedWallet() -> Wallet? {
        walletSubject.value
    }

    func getPrice(for symbol: String) -> Double {
        pricesService.currentPrice(for: symbol)?.value ?? 0
    }

    func getPrices(for symbols: [String]) -> [String: Double] {
        var dict = [String: Double]()
        for symbol in symbols {
            dict[symbol] = getPrice(for: symbol)
        }
        return dict
    }

    func getSendService() -> SendServiceType {
        sendService
    }

    func getFreeTransactionFeeLimit() async throws -> UsageStatus {
        Single.async { try await self.sendService.getFreeTransactionFeeLimit() }
    }

    func navigate(to scene: SendToken.NavigatableScene) {
        navigationSubject.accept(scene)
    }

    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network) {
        recipientSubject.accept(nil)
        navigationSubject.accept(.chooseRecipientAndNetwork(showAfterConfirmation: true, preSelectedNetwork: network))
    }

    func chooseWallet(_ wallet: Wallet) {
        analyticsManager.log(
            event: .sendSelectTokenClick(tokenTicker: wallet.token.symbol)
        )
        walletSubject.accept(wallet)

        if !wallet.token.isRenBTC, networkSubject.value == .bitcoin {
            selectNetwork(.solana)
        }
    }

    func cleanAllFields() {
        amountSubject.accept(nil)
        recipientSubject.accept(nil)
    }

    func shouldShowConfirmAlert() -> Bool {
        Defaults.shouldShowConfirmAlertOnSend
    }

    func closeConfirmAlert() {
        Defaults.shouldShowConfirmAlertOnSend = false
    }

    func authenticateAndSend() {
        authenticationHandler.authenticate(
            presentationStyle:
            .init(
                completion: { [weak self] _ in
                    self?.send()
                }
            )
        )
    }
}
