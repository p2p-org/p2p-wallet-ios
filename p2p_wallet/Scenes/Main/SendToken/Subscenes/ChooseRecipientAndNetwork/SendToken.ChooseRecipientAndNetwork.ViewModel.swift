//
//  SendToken.ChooseRecipientAndNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Combine
import FeeRelayerSwift
import Foundation
import Resolver
import SolanaSwift

protocol SendTokenChooseRecipientAndNetworkViewModelType: SendTokenRecipientAndNetworkHandler,
    SendTokenSelectNetworkViewModelType
{
    // Navigation
    var navigationPublisher: AnyPublisher<SendToken.ChooseRecipientAndNetwork.NavigatableScene?, Never> { get }
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.NavigatableScene)

    // Properties
    var preSelectedNetwork: SendToken.Network? { get }
    var walletPublisher: AnyPublisher<Wallet?, Never> { get }
    var amountPublisher: AnyPublisher<Double?, Never> { get }

    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
    func getSendService() -> SendServiceType
    func getPrice(for symbol: String) -> Double
    func getPrices(for symbols: [String]) -> [String: Double]
    func save()
    func navigateNext()
}

extension SendToken.ChooseRecipientAndNetwork {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        let sendService: SendServiceType
        private let sendTokenViewModel: SendTokenViewModelType
        let showAfterConfirmation: Bool
        let preSelectedNetwork: SendToken.Network?
        @Injected var walletRepository: WalletsRepository

        // MARK: - Properties

        private let relayMethod: SendTokenRelayMethod
        var subscriptions = [AnyCancellable]()

        // MARK: - Subjects

        @Published private var navigatableScene: NavigatableScene?
        @Published var recipient: SendToken.Recipient?
        @Published var network: SendToken.Network = .solana
        @Published var payingWallet: Wallet?
        let feeInfoSubject = LoadableRelay<SendToken.FeeInfo>(
            request: {
                .init(feeAmount: .zero, feeAmountInSOL: .zero, hasAvailableWalletToPayFee: nil)
            }
        )

        // MARK: - Initializers

        init(
            showAfterConfirmation: Bool,
            preSelectedNetwork: SendToken.Network?,
            sendTokenViewModel: SendTokenViewModelType,
            relayMethod: SendTokenRelayMethod
        ) {
            self.showAfterConfirmation = showAfterConfirmation
            self.preSelectedNetwork = preSelectedNetwork
            self.sendTokenViewModel = sendTokenViewModel
            self.relayMethod = relayMethod
            sendService = Resolver.resolve(args: relayMethod)
            bind()

            if let preSelectedNetwork = preSelectedNetwork {
                selectNetwork(preSelectedNetwork)
            }
        }

        func bind() {
            sendTokenViewModel.recipientDriver
                .sink { [weak self] recipient in
                    self?.setRecipient(recipient)
                }
                .store(in: &subscriptions)

            sendTokenViewModel.networkDriver
                .sink { [weak self] network in
                    self?.setNetwork(network)
                }
                .store(in: &subscriptions)

            sendTokenViewModel.payingWalletDriver
                .sink { [weak self] payingWallet in
                    self?.setPayingWallet(payingWallet)
                }
                .store(in: &subscriptions)

            // Smart select fee token
            $recipient
                .flatMapLatest { [weak self] _ -> Single<FeeAmount?> in
                    guard
                        let self = self,
                        let wallet = self.sendTokenViewModel.walletSubject.value,
                        let receiver = self.recipientSubject.value
                    else { return .just(.zero) }

                    return Single.async {
                        try await self.sendService.getFees(
                            from: wallet,
                            receiver: receiver.address,
                            network: self.networkSubject.value,
                            payingTokenMint: wallet.mintAddress
                        )
                    }
                    .flatMap { [weak self] fee -> Single<FeeAmount?> in
                        guard let self = self, let fee = fee else { return .just(.zero) }

                        return Single.async {
                            try await self.sendService.getFeesInPayingToken(
                                feeInSOL: fee,
                                payingFeeWallet: wallet
                            )
                        }
                    }
                }
                .subscribe(onNext: { [weak self] fee in
                    guard
                        let self = self,
                        let amount = self.sendTokenViewModel.amountSubject.value,
                        let wallet = self.sendTokenViewModel.walletSubject.value,
                        let fee = fee
                    else { return }

                    if amount.toLamport(decimals: wallet.token.decimals) + fee.total > (wallet.lamports ?? 0) {
                        self.payingWalletSubject.accept(self.walletRepository.nativeWallet)
                    } else {
                        self.payingWalletSubject.accept(wallet)
                    }
                })
                .disposed(by: disposeBag)

            bindFees()
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.ViewModel: SendTokenChooseRecipientAndNetworkViewModelType {
    func setRecipient(_ recipient: SendToken.Recipient?) {
        self.recipient = recipient
    }

    var recipientPublisher: AnyPublisher<SendToken.Recipient?, Never> {
        $recipient.eraseToAnyPublisher()
    }

    func setNetwork(_ network: SendToken.Network?) {
        guard let network = network else {
            return
        }
        self.network = network
    }

    var networkPublisher: AnyPublisher<SendToken.Network, Never> {
        $network.eraseToAnyPublisher()
    }

    func setPayingWallet(_ payingWallet: Wallet?) {
        self.payingWallet = payingWallet
    }

    var payingWalletPublisher: AnyPublisher<Wallet?, Never> {
        $payingWallet.eraseToAnyPublisher()
    }

    var feeInfoPublisher: AnyPublisher<Loadable<SendToken.FeeInfo>, Never> {
        feeInfoSubject.eraseToAnyPublisher()
    }

    var navigationPublihser: AnyPublisher<SendToken.ChooseRecipientAndNetwork.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var walletPublisher: AnyPublisher<Wallet?, Never> {
        sendTokenViewModel.walletPublisher
    }

    var amountPublisher: AnyPublisher<Double?, Never> {
        sendTokenViewModel.amountPublisher
    }

    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.NavigatableScene) {
        navigatableScene = scene
    }

    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel(
            chooseRecipientAndNetworkViewModel: self,
            showAfterConfirmation: showAfterConfirmation,
            relayMethod: relayMethod,
            amount: sendTokenViewModel.amount ?? 0
        )
        return vm
    }

    func getSendService() -> SendServiceType {
        sendTokenViewModel.getSendService()
    }

    func getPrice(for symbol: String) -> Double {
        sendTokenViewModel.getPrice(for: symbol)
    }

    func getPrices(for symbols: [String]) -> [String: Double] {
        sendTokenViewModel.getPrices(for: symbols)
    }

    func getFreeTransactionFeeLimit() async throws -> UsageStatus {
        try await sendTokenViewModel.getFreeTransactionFeeLimit()
    }

    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network) {
        sendTokenViewModel.navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(network)
    }

    func save() {
        sendTokenViewModel.setRecipient(recipient)
        sendTokenViewModel.setNetwork(network)
        sendTokenViewModel.setPayingWallet(payingWallet)
    }

    func navigateNext() {
        if showAfterConfirmation {
            navigatableScene = .backToConfirmation
        } else {
            sendTokenViewModel.navigate(to: .confirmation)
        }
    }
}
