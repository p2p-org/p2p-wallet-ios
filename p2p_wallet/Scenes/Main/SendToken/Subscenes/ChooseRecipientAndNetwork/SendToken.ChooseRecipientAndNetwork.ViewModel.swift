//
//  SendToken.ChooseRecipientAndNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenChooseRecipientAndNetworkViewModelType {
    var showAfterConfirmation: Bool {get}
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.NavigatableScene?> {get}
    var walletDriver: Driver<Wallet?> {get}
    var amountDriver: Driver<SolanaSDK.Lamports?> {get}
    var recipientDriver: Driver<SendToken.Recipient?> {get}
    var networkDriver: Driver<SendToken.Network> {get}
    
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.NavigatableScene)
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
    func getAPIClient() -> SendTokenAPIClient
    func getSelectedRecipient() -> SendToken.Recipient?
    func getPrice(for symbol: String) -> Double
    func getSOLAndRenBTCPrices() -> [String: Double]
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedNetwork() -> SendToken.Network
    func selectRecipient(_ recipient: SendToken.Recipient?)
    func selectNetwork(_ network: SendToken.Network)
}

extension SendToken.ChooseRecipientAndNetwork {
    class ViewModel {
        // MARK: - Dependencies
        private let sendTokenViewModel: SendTokenViewModelType
        let showAfterConfirmation: Bool
        
        // MARK: - Properties
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        // MARK: - Initializers
        init(sendTokenViewModel: SendTokenViewModelType, showAfterConfirmation: Bool) {
            self.sendTokenViewModel = sendTokenViewModel
            self.showAfterConfirmation = showAfterConfirmation
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.ViewModel: SendTokenChooseRecipientAndNetworkViewModelType {
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var walletDriver: Driver<Wallet?> {
        sendTokenViewModel.walletDriver
    }
    
    var amountDriver: Driver<SolanaSDK.Lamports?> {
        sendTokenViewModel.amountDriver
    }
    
    var recipientDriver: Driver<SendToken.Recipient?> {
        
    }
    
    // MARK: - Actions
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel(
            chooseRecipientAndNetworkViewModel: self,
            showAfterConfirmation: showAfterConfirmation
        )
        vm.nextHandler = { [weak self] in
            guard let self = self else {return}
            if self.showAfterConfirmation {
                self.navigationSubject.accept(.backToConfirmation)
            } else {
                self.sendTokenViewModel.navigate(to: .confirmation)
            }
        }
        return vm
    }
    
    func getAPIClient() -> SendTokenAPIClient {
        sendTokenViewModel.getAPIClient()
    }
    
    func getSelectedRecipient() -> SendToken.Recipient? {
        
    }
}
