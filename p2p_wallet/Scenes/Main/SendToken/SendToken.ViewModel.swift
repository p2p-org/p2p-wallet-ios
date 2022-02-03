//
//  SendToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenViewModelType: SendTokenRecipientAndNetworkHandler, SendTokenTokenAndAmountHandler, SendTokenSelectNetworkViewModelType {
    var navigationDriver: Driver<SendToken.NavigatableScene> {get}
    
    func getPrice(for symbol: String) -> Double
    func getSOLAndRenBTCPrices() -> [String: Double]
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSelectedNetwork() -> SendToken.Network
    func getSelectedAmount() -> Double?
    
    func navigate(to scene: SendToken.NavigatableScene)
    func chooseWallet(_ wallet: Wallet)
    
    func shouldShowConfirmAlert() -> Bool
    func closeConfirmAlert()
    
    func authenticateAndSend()
}

extension SendToken {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var addressFormatter: AddressFormatterType
        @Injected private var authenticationHandler: AuthenticationHandlerType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        @Injected var sendService: SendServiceType
        
        // MARK: - Properties
        private let initialWalletPubkey: String?
        private let initialDestinationWalletPubkey: String?
        
        private var selectedNetwork: SendToken.Network?
        private var selectableNetworks: [SendToken.Network]?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene>(value: .chooseTokenAndAmount(showAfterConfirmation: false))
        let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        let amountSubject = BehaviorRelay<Double?>(value: nil)
        let recipientSubject = BehaviorRelay<Recipient?>(value: nil)
        let networkSubject = BehaviorRelay<Network>(value: .solana)
        let payingWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        
        // MARK: - Initializers
        init(
            walletPubkey: String?,
            destinationAddress: String?
        ) {
            self.initialWalletPubkey = walletPubkey
            self.initialDestinationWalletPubkey = destinationAddress
            
            // accept initial values
            if let pubkey = walletPubkey {
                walletSubject.accept(walletsRepository.getWallets().first(where: {$0.pubkey == pubkey}))
            } else {
                walletSubject.accept(walletsRepository.nativeWallet)
            }
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        private func send() {
            guard let wallet = walletSubject.value,
                  let amount = amountSubject.value,
                  let receiver = recipientSubject.value?.address
            else {return}
            
            let network = networkSubject.value
            
            // form request
            let request = sendService.send(
                from: wallet,
                receiver: receiver,
                amount: amount,
                network: network,
                payingFeeWallet: payingWalletSubject.value
            )
            
            // detect network
            let fee: SolanaSDK.Lamports
            switch network {
            case .solana:
                fee = 0
            case .bitcoin:
                fee = network.defaultFees.first(where: {$0.unit == "renBTC"})?.amount.toLamport(decimals: 8) ?? 0 // TODO: solana fee
            }
            
            // log
            analyticsManager.log(
                event: .sendSendClick(
                    tokenTicker: wallet.token.symbol,
                    sum: amount
                )
            )
            
            // show processing scene
            navigationSubject.accept(
                .processTransaction(
                    request: request.map {$0 as ProcessTransactionResponseType},
                    transactionType: .send(
                        from: wallet,
                        to: receiver,
                        lamport: amount.toLamport(decimals: wallet.token.decimals),
                        feeInLamports: fee
                    )
                )
            )
        }
    }
}

extension SendToken.ViewModel: SendTokenViewModelType {
    var navigationDriver: Driver<SendToken.NavigatableScene> {
        navigationSubject.asDriver()
    }
    
    func getSelectedWallet() -> Wallet? {
        walletSubject.value
    }
    
    func getPrice(for symbol: String) -> Double {
        pricesService.currentPrice(for: symbol)?.value ?? 0
    }
    
    func getSOLAndRenBTCPrices() -> [String: Double] {
        [
            "SOL": getPrice(for: "SOL"),
            "renBTC": getPrice(for: "renBTC")
        ]
    }
    
    func getSendService() -> SendServiceType {
        sendService
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
        
        if !wallet.token.isRenBTC && networkSubject.value == .bitcoin {
            networkSubject.accept(.solana)
            recipientSubject.accept(nil)
        }
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
                    isRequired: false,
                    isFullScreen: false,
                    completion: { [weak self] in
                        self?.send()
                    }
                )
        )
    }
    
    // MARK: - Helpers
    private func isRecipientBTCAddress() -> Bool {
        guard let recipient = recipientSubject.value else {return false}
        return recipient.name == nil &&
            recipient.address
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: sendService.isTestNet()))
    }
}
