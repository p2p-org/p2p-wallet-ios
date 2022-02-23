//
//  SendToken.ChooseRecipientAndNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxSwift
import RxCocoa
import FeeRelayerSwift

protocol SendTokenChooseRecipientAndNetworkViewModelType: SendTokenRecipientAndNetworkHandler, SendTokenSelectNetworkViewModelType {
    var showAfterConfirmation: Bool {get}
    var preSelectedNetwork: SendToken.Network? {get}
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.NavigatableScene?> {get}
    var walletDriver: Driver<Wallet?> {get}
    var amountDriver: Driver<Double?> {get}
    
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.NavigatableScene)
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
    func getSendService() -> SendServiceType
    func getPrice(for symbol: String) -> Double
    func getPrices(for symbols: [String]) -> [String: Double]
    func save()
    func navigateNext()
}

extension SendToken.ChooseRecipientAndNetwork {
    class ViewModel {
        // MARK: - Dependencies
        let sendService: SendServiceType
        private let sendTokenViewModel: SendTokenViewModelType
        let showAfterConfirmation: Bool
        let preSelectedNetwork: SendToken.Network?
        
        // MARK: - Properties
        private let relayMethod: SendTokenRelayMethod
        let disposeBag = DisposeBag()
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        let recipientSubject = BehaviorRelay<SendToken.Recipient?>(value: nil)
        let networkSubject = BehaviorRelay<SendToken.Network>(value: .solana)
        let payingWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        let feeInfoSubject = LoadableRelay<SendToken.FeeInfo>(request: .just(.zero))
        
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
            self.sendService = Resolver.resolve(args: relayMethod)
            bind()
            
            if let preSelectedNetwork = preSelectedNetwork {
                selectNetwork(preSelectedNetwork)
            }
        }
        
        func bind() {
            sendTokenViewModel.recipientDriver
                .drive(recipientSubject)
                .disposed(by: disposeBag)
            
            sendTokenViewModel.networkDriver
                .drive(networkSubject)
                .disposed(by: disposeBag)
            
            sendTokenViewModel.payingWalletDriver
                .drive(payingWalletSubject)
                .disposed(by: disposeBag)
            
            bindFees()
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.ViewModel: SendTokenChooseRecipientAndNetworkViewModelType {
    func getSelectedWallet() -> Wallet? {
        sendTokenViewModel.getSelectedWallet()
    }
    
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var walletDriver: Driver<Wallet?> {
        sendTokenViewModel.walletDriver
    }
    
    var amountDriver: Driver<Double?> {
        sendTokenViewModel.amountDriver
    }
    
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel(
            chooseRecipientAndNetworkViewModel: self,
            showAfterConfirmation: showAfterConfirmation,
            relayMethod: relayMethod
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
    
    func getFreeTransactionFeeLimit() -> Single<FeeRelayer.Relay.FreeTransactionFeeLimit> {
        sendTokenViewModel.getFreeTransactionFeeLimit()
    }
    
    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network) {
        sendTokenViewModel.navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(network)
    }
    
    func save() {
        sendTokenViewModel.selectRecipient(recipientSubject.value)
        sendTokenViewModel.selectNetwork(networkSubject.value)
        sendTokenViewModel.payingWalletSubject.accept(payingWalletSubject.value)
    }
    
    func navigateNext() {
        if showAfterConfirmation {
            navigationSubject.accept(.backToConfirmation)
        } else {
            sendTokenViewModel.navigate(to: .confirmation)
        }
    }
}
