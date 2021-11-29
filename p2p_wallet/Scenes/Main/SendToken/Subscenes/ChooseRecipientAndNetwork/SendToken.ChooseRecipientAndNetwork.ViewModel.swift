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
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.NavigatableScene?> {get}
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.NavigatableScene)
}

extension SendToken.ChooseRecipientAndNetwork {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension SendToken.ChooseRecipientAndNetwork.ViewModel: SendTokenChooseRecipientAndNetworkViewModelType {
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
