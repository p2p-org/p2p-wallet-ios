//
//  SendTokenChooseRecipientAndNetwork.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenChooseRecipientAndNetworkViewModelType {
    var navigationDriver: Driver<SendTokenChooseRecipientAndNetwork.NavigatableScene?> {get}
    func navigate(to scene: SendTokenChooseRecipientAndNetwork.NavigatableScene)
}

extension SendTokenChooseRecipientAndNetwork {
    class ViewModel {
        // MARK: - Dependencies
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension SendTokenChooseRecipientAndNetwork.ViewModel: SendTokenChooseRecipientAndNetworkViewModelType {
    var navigationDriver: Driver<SendTokenChooseRecipientAndNetwork.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendTokenChooseRecipientAndNetwork.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
