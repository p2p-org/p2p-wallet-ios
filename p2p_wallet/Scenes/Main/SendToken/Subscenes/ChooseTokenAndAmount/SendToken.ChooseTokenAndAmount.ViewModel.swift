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

    var navigationDriver: AnyPublisher<SendToken.ChooseTokenAndAmount.NavigatableScene?, Never> { get }
    var currencyModeDriver: AnyPublisher<SendToken.ChooseTokenAndAmount.CurrencyMode, Never> { get }
    var errorDriver: AnyPublisher<SendToken.ChooseTokenAndAmount.Error?, Never> { get }
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
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var walletsRepository: WalletsRepository
        private let sendTokenViewModel: SendTokenViewModelType

        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()
        let showAfterConfirmation: Bool
        let initialAmount: Double?
        let selectedNetwork: SendToken.Network?

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let currencyModeSubject = BehaviorRelay<CurrencyMode>(value: .token)
        let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        let amountSubject = BehaviorRelay<Double?>(value: nil)
        let clearForm = CurrentValueSubject<Void, Never>()

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
            bind()
        }

        private func bind() {
            #if DEBUG
                amountSubject.subscribe(onNext: { debugPrint($0 ?? 0) }).disposed(by: disposeBag)
            #endif

            sendTokenViewModel.walletDriver
                .drive(walletSubject)
                .disposed(by: disposeBag)

            sendTokenViewModel.amountDriver
                .drive(amountSubject)
                .disposed(by: disposeBag)

            clearForm
                .subscribe(onNext: { _ in self.clear() })
                .disposed(by: disposeBag)
        }
    }
}

extension SendToken.ChooseTokenAndAmount.ViewModel: SendTokenChooseTokenAndAmountViewModelType {
    var canGoBack: Bool {
        sendTokenViewModel.canGoBack
    }

    var navigationDriver: AnyPublisher<SendToken.ChooseTokenAndAmount.NavigatableScene?, Never> {
        navigationSubject.asDriver()
    }

    var currencyModeDriver: AnyPublisher<SendToken.ChooseTokenAndAmount.CurrencyMode, Never> {
        currencyModeSubject.asDriver()
    }

    var errorDriver: AnyPublisher<SendToken.ChooseTokenAndAmount.Error?, Never> {
        Driver.combineLatest(
            walletDriver,
            amountDriver,
            currencyModeDriver
        )
            .map { [weak self] wallet, amount, _ in
                if wallet == nil { return .destinationWalletIsMissing }
                if amount == nil || (amount ?? 0) <= 0 { return .invalidAmount }
                if (amount ?? 0) > (self?.calculateAvailableAmount() ?? 0) { return .insufficientFunds }
                return nil
            }
    }

    // MARK: - Actions

    func navigate(to scene: SendToken.ChooseTokenAndAmount.NavigatableScene) {
        if scene == .chooseWallet {
            analyticsManager.log(event: .tokenListViewed(lastScreen: "Send", tokenListLocation: "Token_A"))
        }
        navigationSubject.accept(scene)
    }

    func cancelSending() {
        sendTokenViewModel.navigate(to: .back)
    }

    func toggleCurrencyMode() {
        if currencyModeSubject.value == .token {
            currencyModeSubject.accept(.fiat)
        } else {
            currencyModeSubject.accept(.token)
        }
    }

    func calculateAvailableAmount() -> Double? {
        guard let wallet = walletSubject.value else { return nil }
        // all amount
        var availableAmount = wallet.amount ?? 0

        // convert to fiat in fiat mode
        if currencyModeSubject.value == .fiat {
            availableAmount = (availableAmount * wallet.priceInCurrentFiat).rounded(decimals: wallet.token.decimals)
        }

        #if DEBUG
            debugPrint("availableAmount \(availableAmount)")
        #endif

        // return
        return availableAmount > 0 ? availableAmount : 0
    }

    func isTokenValidForSelectedNetwork() -> Bool {
        let isValid = selectedNetwork != .bitcoin || walletSubject.value?.token.isRenBTC == true
        if !isValid, showAfterConfirmation {
            navigationSubject.accept(.invalidTokenForSelectedNetworkAlert)
        }
        return isValid
    }

    func save() {
        guard let wallet = walletSubject.value,
              let totalLamports = wallet.lamports,
              var amount = amountSubject.value
        else { return }

        // convert value
        if currencyModeSubject.value == .fiat, (wallet.priceInCurrentFiat ?? 0) > 0 {
            amount /= wallet.priceInCurrentFiat!
        }

        // calculate lamports
        var lamports = amount.toLamport(decimals: wallet.token.decimals)
        if lamports > totalLamports {
            lamports = totalLamports
        }

        sendTokenViewModel.chooseWallet(wallet)
        sendTokenViewModel.enterAmount(lamports.convertToBalance(decimals: wallet.token.decimals))
    }

    func clear() {
        // Set Sol as a default wallet by default
        walletSubject.accept(walletsRepository.nativeWallet)
        amountSubject.accept(nil)
    }

    func navigateNext() {
        sendTokenViewModel
            .navigate(to: .chooseRecipientAndNetwork(showAfterConfirmation: showAfterConfirmation,
                                                     preSelectedNetwork: nil))
    }
}
