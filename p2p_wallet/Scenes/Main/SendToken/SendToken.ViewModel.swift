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
    
    func createChooseTokenAndAmountViewModel() -> SendTokenChooseTokenAndAmountViewModelType
    func createChooseRecipientAndNetworkViewModel() -> SendTokenChooseRecipientAndNetworkViewModelType
    
    func navigate(to scene: SendToken.NavigatableScene)
    func getSelectedWallet() -> SolanaSDK.Wallet?
    func getSelectedAmount() -> Double?
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSelectedNetwork() -> SendToken.Network?
    func getRenBTCPrice() -> Double
    func getSelectedTokenPrice() -> Double
    
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
        
        private var selectedWalletPubkey: String?
        private var selectedAmount: SolanaSDK.Lamports?
        private var selectedRecipient: SendToken.Recipient?
        private var selectedNetwork: SendToken.Network?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene>(value: .chooseTokenAndAmount)
        
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
            guard let wallet = getSelectedWallet(),
                  let sender = selectedWalletPubkey,
                  let amount = selectedAmount,
                  let receiver = selectedRecipient?.address,
                  let network = selectedNetwork
            else {return}
            
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
    
    // MARK: - Actions
    func createChooseTokenAndAmountViewModel() -> SendTokenChooseTokenAndAmountViewModelType {
        let vm = SendToken.ChooseTokenAndAmount.ViewModel(repository: walletsRepository, walletPubkey: initialWalletPubkey)
        vm.onGoBack = {[weak self] in
            self?.navigate(to: .back)
        }
        vm.onSelect = {[weak self] pubkey, lamports in
            self?.selectedWalletPubkey = pubkey
            self?.selectedAmount = lamports
            self?.navigate(to: .chooseRecipientAndNetwork)
        }
        return vm
    }
    
    func createChooseRecipientAndNetworkViewModel() -> SendTokenChooseRecipientAndNetworkViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.ViewModel()
        vm.solanaAPIClient = solanaAPIClient
        vm.repository = walletsRepository
        vm.selectedWalletPubkey = selectedWalletPubkey
        vm.selectedAmount = selectedAmount
        vm.pricesService = pricesService
        vm.completion = {[weak self] recipient, network in
            self?.selectedRecipient = recipient
            self?.selectedNetwork = network
            self?.navigate(to: .confirmation)
        }
        return vm
    }
    
    func navigate(to scene: SendToken.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func getSelectedWallet() -> SolanaSDK.Wallet? {
        walletsRepository.getWallets().first(where: {$0.pubkey == selectedWalletPubkey})
    }
    
    func getSelectedAmount() -> Double? {
        selectedAmount?.convertToBalance(decimals: getSelectedWallet()?.token.decimals)
    }
    
    func getSelectedRecipient() -> SendToken.Recipient? {
        selectedRecipient
    }
    
    func getSelectedNetwork() -> SendToken.Network? {
        selectedNetwork
    }
    
    func getRenBTCPrice() -> Double {
        pricesService.currentPrice(for: "renBTC")?.value ?? 0
    }
    
    func getSelectedTokenPrice() -> Double {
        pricesService.currentPrice(for: getSelectedWallet()?.token.symbol ?? "USDC")?.value ?? 0
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
}
