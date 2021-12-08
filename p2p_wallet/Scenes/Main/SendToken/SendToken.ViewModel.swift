//
//  SendToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenViewModelType {
    var navigationDriver: Driver<SendToken.NavigatableScene> {get}
    var walletDriver: Driver<Wallet?> {get}
    var amountDriver: Driver<SolanaSDK.Lamports?> {get}
    var recipientDriver: Driver<SendToken.Recipient?> {get}
    var networkDriver: Driver<SendToken.Network> {get}
    
    func createChooseTokenAndAmountViewModel() -> SendTokenChooseTokenAndAmountViewModelType
    func createChooseRecipientAndNetworkViewModel() -> SendTokenChooseRecipientAndNetworkViewModelType
    
    func getRenBTCPrice() -> Double
    func getSOLPrice() -> Double
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedNetwork() -> SendToken.Network
    
    func navigate(to scene: SendToken.NavigatableScene)
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
        private let navigationSubject = BehaviorRelay<NavigatableScene>(value: .chooseTokenAndAmount)
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let amountSubject = BehaviorRelay<SolanaSDK.Lamports?>(value: nil)
        private let recipientSubject = BehaviorRelay<Recipient?>(value: nil)
        private let networkSubject = BehaviorRelay<Network>(value: .solana)
        
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
                fee = network.defaultFee.amount.toLamport(decimals: 8)
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
    
    var recipientDriver: Driver<SendToken.Recipient?> {
        recipientSubject.asDriver()
    }
    
    var networkDriver: Driver<SendToken.Network> {
        networkSubject.asDriver()
    }
    
    func createChooseTokenAndAmountViewModel() -> SendTokenChooseTokenAndAmountViewModelType {
        let vm = SendToken.ChooseTokenAndAmount.ViewModel(
            walletSubject: walletSubject,
            amountInLamportsSubject: amountSubject
        )
        vm.onGoBack = {[weak self] in
            self?.navigate(to: .back)
        }
        return vm
    }
    
    func createChooseRecipientAndNetworkViewModel() -> SendTokenChooseRecipientAndNetworkViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.ViewModel()
        
        vm.getSelectableNetworks = {[weak self] in
            self?.getSelectableNetworks() ?? []
        }
        
        vm.solanaAPIClient = solanaAPIClient
        vm.repository = walletsRepository
        vm.selectedWalletPubkey = selectedWalletPubkey
        vm.selectedAmount = selectedAmount
        vm.pricesService = pricesService
        vm.completion = {[weak self] recipient, network, selectableNetworks in
            self?.selectedRecipient = recipient
            self?.selectedNetwork = network
            self?.selectableNetworks = selectableNetworks
            self?.navigate(to: .confirmation)
        }
        return vm
    }
    
    func getRenBTCPrice() -> Double {
        pricesService.currentPrice(for: "renBTC")?.value ?? 0
    }
    
    func getSOLPrice() -> Double {
        pricesService.currentPrice(for: "SOL")?.value ?? 0
    }
    
    func getSelectableNetworks() -> [SendToken.Network] {
        var networks: [SendToken.Network] = [.solana]
        if isRecipientBTCAddress() {
            networks.append(.bitcoin)
        }
        return networks
    }
    
    func getSelectedNetwork() -> SendToken.Network {
        networkSubject.value
    }
    
    func navigate(to scene: SendToken.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func selectNetwork(_ network: SendToken.Network) {
        if walletSubject.value?.token.isRenBTC == false {
            networkSubject.accept(.solana)
        }
        networkSubject.accept(network)
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
