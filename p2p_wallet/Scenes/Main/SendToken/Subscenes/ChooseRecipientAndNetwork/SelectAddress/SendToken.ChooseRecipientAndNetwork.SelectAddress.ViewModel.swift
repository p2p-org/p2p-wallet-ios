//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

protocol SendTokenChooseRecipientAndNetworkSelectAddressViewModelType: WalletDidSelectHandler {
    var relayMethod: SendTokenRelayMethod { get }
    var showAfterConfirmation: Bool { get }
    var preSelectedNetwork: SendToken.Network? { get }
    var recipientsListViewModel: SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientsListViewModel { get }
    var navigationPublisher: AnyPublisher<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?, Never> {
        get
    }
    var inputStatePublisher: AnyPublisher<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState, Never> { get }
    var searchTextPublisher: AnyPublisher<String?, Never> { get }
    var walletPublisher: AnyPublisher<Wallet?, Never> { get }
    var recipientPublisher: AnyPublisher<SendToken.Recipient?, Never> { get }
    var networkPublisher: AnyPublisher<SendToken.Network, Never> { get }
    var payingWalletPublisher: AnyPublisher<Wallet?, Never> { get }
    var feeInfoPublisher: AnyPublisher<Loadable<SendToken.FeeInfo>, Never> { get }
    var warningPublisher: AnyPublisher<String?, Never> { get }
    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    func getCurrentInputState() -> SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState
    func getCurrentSearchKey() -> String?
    func getPrice(for symbol: String) -> Double
    func getPrices(for symbols: [String]) -> [String: Double]
    func getFeeInCurrentFiat() -> String
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene)
    func navigateToChoosingNetworkScene()

    func userDidTapPaste()
    func search(_ address: String?)

    func selectRecipient(_ recipient: SendToken.Recipient)
    func clearRecipient()

    func next()
}

extension SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
    func clearSearching() {
        search(nil)
    }
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        private let chooseRecipientAndNetworkViewModel: SendTokenChooseRecipientAndNetworkViewModelType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var solanaAPIClient: SolanaAPIClient

        let minSolForSending = 0.0009
        private let amount: Double

        // MARK: - Properties

        let relayMethod: SendTokenRelayMethod
        private var subscriptions = [AnyCancellable]()
        let recipientsListViewModel = RecipientsListViewModel()
        let showAfterConfirmation: Bool

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        @Published private var inputState = InputState.searching
        @Published private var searchText: String?

        init(
            chooseRecipientAndNetworkViewModel: SendTokenChooseRecipientAndNetworkViewModelType,
            showAfterConfirmation: Bool,
            relayMethod: SendTokenRelayMethod,
            amount: Double
        ) {
            self.relayMethod = relayMethod
            self.chooseRecipientAndNetworkViewModel = chooseRecipientAndNetworkViewModel
            self.showAfterConfirmation = showAfterConfirmation
            self.amount = amount
            recipientsListViewModel.solanaAPIClient = chooseRecipientAndNetworkViewModel.getSendService()
            recipientsListViewModel.preSelectedNetwork = preSelectedNetwork

            if chooseRecipientAndNetworkViewModel.getSelectedRecipient() != nil {
                if showAfterConfirmation {
                    inputState = .recipientSelected
                } else {
                    clearRecipient()
                }
            }
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress
    .ViewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
{
    var preSelectedNetwork: SendToken.Network? {
        chooseRecipientAndNetworkViewModel.preSelectedNetwork
    }

    var navigationPublisher: AnyPublisher<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var inputStatePublisher: AnyPublisher<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState, Never> {
        $inputState.eraseToAnyPublisher()
    }

    var searchTextPublisher: AnyPublisher<String?, Never> {
        $searchText.eraseToAnyPublisher()
    }

    var walletPublisher: AnyPublisher<Wallet?, Never> {
        chooseRecipientAndNetworkViewModel.walletPublisher
    }

    var recipientPublisher: AnyPublisher<SendToken.Recipient?, Never> {
        chooseRecipientAndNetworkViewModel.recipientPublisher
    }

    var networkPublisher: AnyPublisher<SendToken.Network, Never> {
        chooseRecipientAndNetworkViewModel.networkPublisher
    }

    var payingWalletPublisher: AnyPublisher<Wallet?, Never> {
        chooseRecipientAndNetworkViewModel.payingWalletPublisher
    }

    var feeInfoPublisher: AnyPublisher<Loadable<SendToken.FeeInfo>, Never> {
        chooseRecipientAndNetworkViewModel.feeInfoPublisher
    }

    var warningPublisher: AnyPublisher<String?, Never> {
        recipientPublisher
            .withLatestFrom(walletPublisher, resultSelector: { ($0, $1) })
            .asyncMap { [weak self] recipient, wallet -> String? in
                guard let self = self,
                      let wallet = wallet,
                      wallet.isNativeSOL,
                      self.amount < self.minSolForSending,
                      let address = recipient?.address
                else { return nil }
                let balance = try await self.solanaAPIClient.getBalance(account: address, commitment: nil)
                guard balance == 0 else { return nil }
                return L10n.youCanTSendLessThan("\(self.minSolForSending) SOL")
            }
//            .switchToLatest() // TODO: - Not work
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            recipientPublisher.map { $0 != nil },
            Publishers.CombineLatest4(
                networkPublisher,
                payingWalletPublisher,
                feeInfoPublisher,
                warningPublisher
            )
                .map { [weak self] network, payingWallet, feeInfo, warning -> Bool in
                    guard let self = self, (warning ?? "").isEmpty else { return false }

                    switch network {
                    case .solana:
                        switch self.relayMethod {
                        case .relay:
                            guard let value = feeInfo.value else { return false }

                            let feeAmountInSOL = value.feeAmountInSOL
                            let feeAmountInToken = value.feeAmount
                            if feeAmountInSOL.total == 0 {
                                return true
                            } else {
                                guard let payingWallet = payingWallet else { return false }
                                return (payingWallet.lamports ?? 0) >= feeAmountInToken.total
                            }
                        case .reward:
                            return true
                        }
                    case .bitcoin:
                        return true
                    }
                }
        )
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }

    func getCurrentInputState() -> SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState {
        inputState
    }

    func getCurrentSearchKey() -> String? {
        searchText
    }

    func getPrice(for symbol: String) -> Double {
        chooseRecipientAndNetworkViewModel.getPrice(for: symbol)
    }

    func getPrices(for symbols: [String]) -> [String: Double] {
        chooseRecipientAndNetworkViewModel.getPrices(for: symbols)
    }

    func getFeeInCurrentFiat() -> String {
        var fee: Double = 0
        if let feeInfo = chooseRecipientAndNetworkViewModel.feeInfoSubject.value {
            let feeInSOL = feeInfo.feeAmountInSOL.total.convertToBalance(decimals: 9)
            fee = feeInSOL * getPrice(for: "SOL")
        }
        return "~\(Defaults.fiat.symbol)\(fee.toString(maximumFractionDigits: 2))"
    }

    // MARK: - Actions

    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene) {
        if scene == .selectPayingWallet {
            analyticsManager.log(event: .tokenListViewed(lastScreen: "Send", tokenListLocation: "Fee"))
        }
        navigatableScene = scene
    }

    func navigateToChoosingNetworkScene() {
        // forward request to chooseRecipientAndNetworkViewModel
        chooseRecipientAndNetworkViewModel.navigate(to: .chooseNetwork)
    }

    func userDidTapPaste() {
        search(clipboardManager.stringFromClipboard())
    }

    func walletDidSelect(_ wallet: Wallet) {
        chooseRecipientAndNetworkViewModel.selectPayingWallet(wallet)
    }

    func search(_ address: String?) {
        searchText = address
        if recipientsListViewModel.searchString != address {
            recipientsListViewModel.searchString = address
            recipientsListViewModel.reload()
        }
    }

    func selectRecipient(_ recipient: SendToken.Recipient) {
        chooseRecipientAndNetworkViewModel.selectRecipient(recipient)
        inputState = .recipientSelected
    }

    func clearRecipient() {
        inputState = .searching
        chooseRecipientAndNetworkViewModel.selectRecipient(nil)
    }

    func next() {
        chooseRecipientAndNetworkViewModel.save()
        chooseRecipientAndNetworkViewModel.navigateNext()
    }
}
