//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?> {get}
    var inputStateDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState> {get}
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene)
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let inputStateSubject = BehaviorRelay<InputState>(value: .entering(nil))
    }
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var inputStateDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState> {
        inputStateSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
