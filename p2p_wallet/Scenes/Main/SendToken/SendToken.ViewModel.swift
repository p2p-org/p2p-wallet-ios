//
//  SendToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenViewModelType: SendTokenRecipientAndNetworkHandler {
    var navigationDriver: Driver<SendToken.NavigatableScene> {get}
    var walletDriver: Driver<Wallet?> {get}
    var amountDriver: Driver<SolanaSDK.Lamports?> {get}
    var recipientDriver: Driver<SendToken.Recipient?> {get}
    var networkDriver: Driver<SendToken.Network> {get}
    
    func getPrice(for symbol: String) -> Double
    func getSOLAndRenBTCPrices() -> [String: Double]
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSelectedNetwork() -> SendToken.Network
    func getSelectedAmount() -> Double?
    
    func navigate(to scene: SendToken.NavigatableScene)
    func chooseWallet(_ wallet: Wallet)
    func enterAmount(_ amount: SolanaSDK.Lamports)
    func selectRecipient(_ recipient: SendToken.Recipient?)
    func selectNetwork(_ network: SendToken.Network)
    
    func shouldShowConfirmAlert() -> Bool
    func closeConfirmAlert()
    
    func authenticateAndSend()
}

extension SendToken {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var addressFormatter: AddressFormatterType
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var analyticsManager: AnalyticsManagerType
        private let walletsRepository: WalletsRepository
        var solanaAPIClient: SendTokenAPIClient
        let pricesService: PricesServiceType
        private let renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        
        // MARK: - Properties
        private let initialWalletPubkey: String?
        private let initialDestinationWalletPubkey: String?
        
        private var selectedNetwork: SendToken.Network?
        private var selectableNetworks: [SendToken.Network]?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene>(value: .chooseTokenAndAmount(showAfterConfirmation: false))
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let amountSubject = BehaviorRelay<SolanaSDK.Lamports?>(value: nil)
        let recipientSubject = BehaviorRelay<Recipient?>(value: nil)
        let networkSubject = BehaviorRelay<Network>(value: .solana)
        
        // MARK: - Initializers
        init(
            repository: WalletsRepository,
            pricesService: PricesServiceType,
            walletPubkey: String?,
            destinationAddress: String?,
            apiClient: SendTokenAPIClient,
            renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        ) {
            self.walletsRepository = repository
            self.pricesService = pricesService
            self.initialWalletPubkey = walletPubkey
            self.initialDestinationWalletPubkey = destinationAddress
            self.solanaAPIClient = apiClient
            self.renVMBurnAndReleaseService = renVMBurnAndReleaseService
            
            // accept initial values
            if let pubkey = walletPubkey {
                walletSubject.accept(repository.getWallets().first(where: {$0.pubkey == pubkey}))
            } else {
                walletSubject.accept(repository.nativeWallet)
            }
        }
        
        private func send() {
            guard let wallet = walletSubject.value,
                  let sender = wallet.pubkey,
                  let amount = amountSubject.value,
                  let receiver = recipientSubject.value?.address
            else {return}
            
            let network = networkSubject.value
            
            // form request
            var request: Single<String>!
            if receiver == sender {
                request = .error(SolanaSDK.Error.other(L10n.youCanNotSendTokensToYourself))
            }
            
            // detect network
            let fee: SolanaSDK.Lamports
            switch network {
            case .solana:
                if wallet.isNativeSOL {
                    request = solanaAPIClient.sendNativeSOL(
                        to: receiver,
                        amount: amount,
                        withoutFee: Defaults.useFreeTransaction,
                        isSimulation: false
                    )
                }
                
                // other tokens
                else {
                    request = solanaAPIClient.sendSPLTokens(
                        mintAddress: wallet.mintAddress,
                        decimals: wallet.token.decimals,
                        from: sender,
                        to: receiver,
                        amount: amount,
                        withoutFee: Defaults.useFreeTransaction,
                        isSimulation: false
                    )
                }
                fee = 0
            case .bitcoin:
                request = renVMBurnAndReleaseService.burn(
                    recipient: receiver,
                    amount: amount
                )
                fee = network.defaultFees.first(where: {$0.unit == "renBTC"})?.amount.toLamport(decimals: 8) ?? 0 // TODO: solana fee
            }
            
            // log
            analyticsManager.log(
                event: .sendSendClick(
                    tokenTicker: wallet.token.symbol,
                    sum: amount.convertToBalance(decimals: wallet.token.decimals)
                )
            )
            
            // show processing scene
            navigationSubject.accept(
                .processTransaction(
                    request: request.map {$0 as ProcessTransactionResponseType},
                    transactionType: .send(
                        from: wallet,
                        to: receiver,
                        lamport: amount,
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
    
    var walletDriver: Driver<Wallet?> {
        walletSubject.asDriver()
    }
    
    var amountDriver: Driver<SolanaSDK.Lamports?> {
        amountSubject.asDriver()
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
    
    func getAPIClient() -> SendTokenAPIClient {
        solanaAPIClient
    }
    
    func getSelectedAmount() -> Double? {
        amountSubject.value?.convertToBalance(decimals: walletSubject.value?.token.decimals)
    }
    
    func navigate(to scene: SendToken.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func chooseWallet(_ wallet: Wallet) {
        analyticsManager.log(
            event: .sendSelectTokenClick(tokenTicker: wallet.token.symbol)
        )
        walletSubject.accept(wallet)
        
        if !wallet.token.isRenBTC && networkSubject.value == .bitcoin {
            networkSubject.accept(.solana)
        }
    }
    
    func enterAmount(_ amount: SolanaSDK.Lamports) {
        amountSubject.accept(amount)
    }
    
    func shouldShowConfirmAlert() -> Bool {
        Defaults.shouldShowConfirmAlert
    }
    
    func closeConfirmAlert() {
        Defaults.shouldShowConfirmAlert = false
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
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()))
    }
}
