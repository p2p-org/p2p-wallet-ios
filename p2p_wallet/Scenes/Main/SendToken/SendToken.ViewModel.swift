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
    
    func set(
        walletPubkey: String?,
        destinationAddress: String?
    )
    
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
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        @Injected var solanaAPIClient: SendTokenAPIClient
        @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        
        // MARK: - Properties
        private var initialWalletPubkey: String?
        private var initialDestinationWalletPubkey: String?
        
        private var selectedNetwork: SendToken.Network?
        private var selectableNetworks: [SendToken.Network]?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene>(value: .chooseTokenAndAmount(showAfterConfirmation: false))
        let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        let amountSubject = BehaviorRelay<Double?>(value: nil)
        let recipientSubject = BehaviorRelay<Recipient?>(value: nil)
        let networkSubject = BehaviorRelay<Network>(value: .solana)
        
        // MARK: - Initializers
        func set(
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
        
        private func send() {
            guard let wallet = walletSubject.value,
                  let sender = wallet.pubkey,
                  let amount = amountSubject.value?.toLamport(decimals: wallet.token.decimals),
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
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()))
    }
}
