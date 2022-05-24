//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

protocol SendTokenChooseRecipientAndNetworkSelectAddressViewModelType: WalletDidSelectHandler {
    var relayMethod: SendTokenRelayMethod { get }
    var showAfterConfirmation: Bool { get }
    var preSelectedNetwork: SendToken.Network? { get }
    var recipientsListViewModel: SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientsListViewModel { get }
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?> { get }
    var inputStateDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState> { get }
    var searchTextDriver: Driver<String?> { get }
    var walletDriver: Driver<Wallet?> { get }
    var recipientDriver: Driver<SendToken.Recipient?> { get }
    var networkDriver: Driver<SendToken.Network> { get }
    var payingWalletDriver: Driver<Wallet?> { get }
    var feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>> { get }
    var warningDriver: Driver<String?> { get }
    var isValidDriver: Driver<Bool> { get }

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
    class ViewModel {
        // MARK: - Dependencies

        private let chooseRecipientAndNetworkViewModel: SendTokenChooseRecipientAndNetworkViewModelType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var analyticsManager: AnalyticsManagerType

        let minSolForSending = 0.0009
        private let amount: Double

        // MARK: - Properties

        let relayMethod: SendTokenRelayMethod
        private let disposeBag = DisposeBag()
        let recipientsListViewModel = RecipientsListViewModel()
        let showAfterConfirmation: Bool

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let inputStateSubject = BehaviorRelay<InputState>(value: .searching)
        private let searchTextSubject = BehaviorRelay<String?>(value: nil)

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
                    inputStateSubject.accept(.recipientSelected)
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

    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var inputStateDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState> {
        inputStateSubject.asDriver()
    }

    var searchTextDriver: Driver<String?> {
        searchTextSubject.asDriver()
    }

    var walletDriver: Driver<Wallet?> {
        chooseRecipientAndNetworkViewModel.walletDriver
    }

    var recipientDriver: Driver<SendToken.Recipient?> {
        chooseRecipientAndNetworkViewModel.recipientDriver
    }

    var networkDriver: Driver<SendToken.Network> {
        chooseRecipientAndNetworkViewModel.networkDriver
    }

    var payingWalletDriver: Driver<Wallet?> {
        chooseRecipientAndNetworkViewModel.payingWalletDriver
    }

    var feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>> {
        chooseRecipientAndNetworkViewModel.feeInfoDriver
    }

    var warningDriver: Driver<String?> {
        walletDriver.map { [weak self] in
            guard let self = self else { return nil }
            return self.amount < self.minSolForSending && ($0?.token.symbol ?? "") == "SOL"
                ? L10n.youCanTSendLessThan("\(self.minSolForSending) SOL")
                : nil
        }
    }

    var isValidDriver: Driver<Bool> {
        var conditionDrivers = [
            recipientDriver.map { $0 != nil },
        ]

        conditionDrivers.append(
            Driver.combineLatest(
                networkDriver,
                payingWalletDriver,
                feeInfoDriver,
                warningDriver
            ).map { [weak self] network, payingWallet, feeInfo, warning -> Bool in
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

        return Driver.combineLatest(conditionDrivers).map { $0.allSatisfy { $0 }}
    }

    func getCurrentInputState() -> SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState {
        inputStateSubject.value
    }

    func getCurrentSearchKey() -> String? {
        searchTextSubject.value
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
        navigationSubject.accept(scene)
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
        searchTextSubject.accept(address)
        if recipientsListViewModel.searchString != address {
            recipientsListViewModel.searchString = address
            recipientsListViewModel.reload()
        }
    }

    func selectRecipient(_ recipient: SendToken.Recipient) {
        chooseRecipientAndNetworkViewModel.selectRecipient(recipient)
        inputStateSubject.accept(.recipientSelected)
    }

    func clearRecipient() {
        inputStateSubject.accept(.searching)
        chooseRecipientAndNetworkViewModel.selectRecipient(nil)
    }

    func next() {
        chooseRecipientAndNetworkViewModel.save()
        chooseRecipientAndNetworkViewModel.navigateNext()
    }
}
