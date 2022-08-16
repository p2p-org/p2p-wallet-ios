//
//  SendToken.ChooseTokenAndAmount.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

protocol SendTokenChooseTokenAndAmountViewModelType: WalletDidSelectHandler, SendTokenTokenAndAmountHandler {
    var initialAmount: Double? { get }

    var navigatableScenePublisher: AnyPublisher<SendToken.ChooseTokenAndAmount.NavigatableScene?, Never> { get }
    var currencyModePublisher: AnyPublisher<SendToken.ChooseTokenAndAmount.CurrencyMode, Never> { get }
    var errorPublisher: AnyPublisher<SendToken.ChooseTokenAndAmount.Error?, Never> { get }
    var clearForm: CurrentValueSubject<Void, Never> { get }
    var showAfterConfirmation: Bool { get }
    var canGoBack: Bool { get }

    func navigate(to scene: SendToken.ChooseTokenAndAmount.NavigatableScene)
    func cancelSending()
    func toggleCurrencyMode()

    func calculateAvailableAmount() -> Double?

    func isTokenValidForSelectedNetwork() -> Bool
    func save()
    func navigateNext()
}

extension SendTokenChooseTokenAndAmountViewModelType {
    func walletDidSelect(_ wallet: Wallet) {
        setWallet(wallet)
    }
}

extension SendToken.ChooseTokenAndAmount {
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var walletsRepository: WalletsRepository
        private let sendTokenViewModel: SendTokenViewModelType

        // MARK: - Properties

        let showAfterConfirmation: Bool
        let initialAmount: Double?
        let selectedNetwork: SendToken.Network?

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        @Published private var currencyMode = CurrencyMode.token
        @Published var wallet: Wallet?
        @Published var amount: Double?
        let clearForm = CurrentValueSubject<Void, Never>(())

        // MARK: - Initializer

        init(
            initialAmount: Double? = nil,
            showAfterConfirmation: Bool = false,
            selectedNetwork: SendToken.Network?,
            sendTokenViewModel: SendTokenViewModelType
        ) {
            self.initialAmount = initialAmount
            self.showAfterConfirmation = showAfterConfirmation
            self.selectedNetwork = selectedNetwork
            self.sendTokenViewModel = sendTokenViewModel
            super.init()
            bind()
        }

        private func bind() {
            #if DEBUG
                $amount.sink { print($0 ?? 0) }.store(in: &subscriptions)
            #endif

            sendTokenViewModel.walletPublisher
                .assign(to: \.wallet, on: self)
                .store(in: &subscriptions)

            sendTokenViewModel.amountPublisher
                .assign(to: \.amount, on: self)
                .store(in: &subscriptions)

            clearForm
                .sink { _ in self.clear() }
                .store(in: &subscriptions)
        }
    }
}

extension SendToken.ChooseTokenAndAmount.ViewModel: SendTokenChooseTokenAndAmountViewModelType {
    func setWallet(_ wallet: Wallet?) {
        self.wallet = wallet
    }

    var walletPublisher: AnyPublisher<Wallet?, Never> {
        $wallet.eraseToAnyPublisher()
    }

    func setAmount(_ amount: Double?) {
        self.amount = amount
    }

    var amountPublisher: AnyPublisher<Double?, Never> {
        $amount.eraseToAnyPublisher()
    }

    var canGoBack: Bool {
        sendTokenViewModel.canGoBack
    }

    var navigatableScenePublisher: AnyPublisher<SendToken.ChooseTokenAndAmount.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var currencyModePublisher: AnyPublisher<SendToken.ChooseTokenAndAmount.CurrencyMode, Never> {
        $currencyMode.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<SendToken.ChooseTokenAndAmount.Error?, Never> {
        Publishers.CombineLatest3(
            $wallet,
            $amount,
            $currencyMode
        )
            .map { [weak self] wallet, amount, _ in
                if wallet == nil { return .destinationWalletIsMissing }
                if amount == nil || (amount ?? 0) <= 0 { return .invalidAmount }
                if (amount ?? 0) > (self?.calculateAvailableAmount() ?? 0) { return .insufficientFunds }
                return nil
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Actions

    func navigate(to scene: SendToken.ChooseTokenAndAmount.NavigatableScene) {
        if scene == .chooseWallet {
            analyticsManager.log(event: .tokenListViewed(lastScreen: "Send", tokenListLocation: "Token_A"))
        }
        navigatableScene = scene
    }

    func cancelSending() {
        sendTokenViewModel.navigate(to: .back)
    }

    func toggleCurrencyMode() {
        if currencyMode == .token {
            currencyMode = .fiat
        } else {
            currencyMode = .token
        }
    }

    func calculateAvailableAmount() -> Double? {
        guard let wallet = wallet else { return nil }
        // all amount
        var availableAmount = wallet.amount ?? 0

        // convert to fiat in fiat mode
        if currencyMode == .fiat {
            availableAmount = (availableAmount * wallet.priceInCurrentFiat).rounded(decimals: wallet.token.decimals)
        }

        #if DEBUG
            print("availableAmount \(availableAmount)")
        #endif

        // return
        return availableAmount > 0 ? availableAmount : 0
    }

    func isTokenValidForSelectedNetwork() -> Bool {
        let isValid = selectedNetwork != .bitcoin || wallet?.token.isRenBTC == true
        if !isValid, showAfterConfirmation {
            navigatableScene = .invalidTokenForSelectedNetworkAlert
        }
        return isValid
    }

    func save() {
        guard let wallet = wallet,
              let totalLamports = wallet.lamports,
              var amount = amount
        else { return }

        // convert value
        if currencyMode == .fiat, (wallet.priceInCurrentFiat ?? 0) > 0 {
            amount /= wallet.priceInCurrentFiat!
        }

        // calculate lamports
        var lamports = amount.toLamport(decimals: wallet.token.decimals)
        if lamports > totalLamports {
            lamports = totalLamports
        }

        sendTokenViewModel.setWallet(wallet)
        sendTokenViewModel.setAmount(lamports.convertToBalance(decimals: wallet.token.decimals))
    }

    func clear() {
        // Set Sol as a default wallet by default
        wallet = walletsRepository.nativeWallet
        amount = nil
    }

    func navigateNext() {
        sendTokenViewModel
            .navigate(to: .chooseRecipientAndNetwork(showAfterConfirmation: showAfterConfirmation,
                                                     preSelectedNetwork: nil))
    }
}
