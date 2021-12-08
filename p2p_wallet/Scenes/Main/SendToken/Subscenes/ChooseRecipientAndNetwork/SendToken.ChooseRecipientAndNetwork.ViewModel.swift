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
    var walletDriver: Driver<Wallet?> {get}
    var amountDriver: Driver<SolanaSDK.Lamports?> {get}
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
}

extension SendToken.ChooseRecipientAndNetwork {
    class ViewModel {
        // MARK: - Dependencies
        private let sendTokenViewModel: SendTokenViewModelType
        
        // MARK: - Properties
        
        // MARK: - Initializers
        init(sendTokenViewModel: SendTokenViewModelType) {
            self.sendTokenViewModel = sendTokenViewModel
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.ViewModel: SendTokenChooseRecipientAndNetworkViewModelType {
    var walletDriver: Driver<Wallet?> {
        sendTokenViewModel.walletDriver
    }
    
    var amountDriver: Driver<SolanaSDK.Lamports?> {
        sendTokenViewModel.amountDriver
    }
    
    // MARK: - Actions
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel()
        vm.solanaAPIClient = solanaAPIClient
        vm.getSelectableNetworks = getSelectableNetworks
        vm.getRenBTCPrice = getRenBTCPrice
        vm.onNext = onNext
        return vm
    }
}
