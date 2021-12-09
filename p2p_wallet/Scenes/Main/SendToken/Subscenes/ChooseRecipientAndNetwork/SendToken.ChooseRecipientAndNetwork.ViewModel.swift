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
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
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
    
    // MARK: - Actions
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel(
            sendTokenViewModel: sendTokenViewModel,
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
}
