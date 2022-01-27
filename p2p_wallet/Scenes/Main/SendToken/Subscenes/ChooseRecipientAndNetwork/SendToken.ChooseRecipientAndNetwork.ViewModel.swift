//
//  SendToken.ChooseRecipientAndNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenChooseRecipientAndNetworkViewModelType: SendTokenRecipientAndNetworkHandler, SendTokenSelectNetworkViewModelType {
    var preSelectedNetwork: SendToken.Network? {get}
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.NavigatableScene?> {get}
    var walletDriver: Driver<Wallet?> {get}
    var amountDriver: Driver<Double?> {get}
    
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.NavigatableScene)
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
    func getAPIClient() -> SendTokenAPIClient
    func getSOLAndRenBTCPrices() -> [String: Double]
    func save()
    func navigateNext()
}

extension SendToken.ChooseRecipientAndNetwork {
    class ViewModel {
        // MARK: - Dependencies
        private let sendTokenViewModel: SendTokenViewModelType
        let showAfterConfirmation: Bool
        let preSelectedNetwork: SendToken.Network?
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        let recipientSubject = BehaviorRelay<SendToken.Recipient?>(value: nil)
        let networkSubject = BehaviorRelay<SendToken.Network>(value: .solana)
        
        // MARK: - Initializers
        init(
            showAfterConfirmation: Bool,
            preSelectedNetwork: SendToken.Network?,
            sendTokenViewModel: SendTokenViewModelType
        ) {
            self.showAfterConfirmation = showAfterConfirmation
            self.preSelectedNetwork = preSelectedNetwork
            self.sendTokenViewModel = sendTokenViewModel
            bind()
            
            if let preSelectedNetwork = preSelectedNetwork {
                networkSubject.accept(preSelectedNetwork)
            }
        }
        
        func bind() {
            sendTokenViewModel.recipientDriver
                .drive(recipientSubject)
                .disposed(by: disposeBag)
            
            sendTokenViewModel.networkDriver
                .drive(networkSubject)
                .disposed(by: disposeBag)
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
            showAfterConfirmation: showAfterConfirmation
        )
        return vm
    }
    
    func getAPIClient() -> SendTokenAPIClient {
        sendTokenViewModel.getAPIClient()
    }

    func getSOLAndRenBTCPrices() -> [String: Double] {
        sendTokenViewModel.getSOLAndRenBTCPrices()
    }
    
    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network) {
        sendTokenViewModel.navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(network)
    }
    
    func save() {
        sendTokenViewModel.selectRecipient(recipientSubject.value)
        sendTokenViewModel.selectNetwork(networkSubject.value)
    }
    
    func navigateNext() {
        if showAfterConfirmation {
            navigationSubject.accept(.backToConfirmation)
        } else {
            sendTokenViewModel.navigate(to: .confirmation)
        }
    }
}
