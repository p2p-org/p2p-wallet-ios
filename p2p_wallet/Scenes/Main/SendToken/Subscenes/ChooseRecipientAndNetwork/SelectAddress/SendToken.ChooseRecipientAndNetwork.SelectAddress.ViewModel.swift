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
    var showAfterConfirmation: Bool {get}
    var recipientsListViewModel: SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientsListViewModel {get}
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?> {get}
    var inputStateDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState> {get}
    var searchTextDriver: Driver<String?> {get}
    var walletDriver: Driver<Wallet?> {get}
    var recipientDriver: Driver<SendToken.Recipient?> {get}
    var networkDriver: Driver<SendToken.Network> {get}
    var isValidDriver: Driver<Bool> {get}
    
    func getPrice(for symbol: String) -> Double
    func getSOLAndRenBTCPrices() -> [String: Double]
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene)
    func navigateToChoosingNetworkScene()
    
    func userDidTapPaste()
    func search(_ address: String?)
    
    func selectRecipient(_ recipient: SendToken.Recipient)
    func clearRecipient()
    
    func next()
}

extension SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
    func clearSearching() {
        search(nil)
    }
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class ViewModel {
        // MARK: - Dependencies
        private let sendTokenViewModel: SendTokenViewModelType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let recipientsListViewModel = RecipientsListViewModel()
        var nextHandler: (() -> Void)?
        let showAfterConfirmation: Bool
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let inputStateSubject = BehaviorRelay<InputState>(value: .searching)
        private let searchTextSubject = BehaviorRelay<String?>(value: nil)
        
        init(sendTokenViewModel: SendTokenViewModelType, showAfterConfirmation: Bool) {
            self.sendTokenViewModel = sendTokenViewModel
            self.showAfterConfirmation = showAfterConfirmation
            recipientsListViewModel.solanaAPIClient = sendTokenViewModel.getAPIClient()
            
            if sendTokenViewModel.getSelectedRecipient() != nil {
                inputStateSubject.accept(.recipientSelected)
            }
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var inputStateDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState> {
        inputStateSubject.asDriver()
    }
    
    var searchTextDriver: Driver<String?> {
        searchTextSubject.asDriver()
    }
    
    var walletDriver: Driver<Wallet?> {
        sendTokenViewModel.walletDriver
    }
    
    var recipientDriver: Driver<SendToken.Recipient?> {
        sendTokenViewModel.recipientDriver
    }
    
    var networkDriver: Driver<SendToken.Network> {
        sendTokenViewModel.networkDriver
    }
    
    var isValidDriver: Driver<Bool> {
        sendTokenViewModel.recipientDriver.map {$0 != nil}
    }
    
    func getPrice(for symbol: String) -> Double {
        sendTokenViewModel.getPrice(for: symbol)
    }
    
    func getSOLAndRenBTCPrices() -> [String: Double] {
        sendTokenViewModel.getSOLAndRenBTCPrices()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func navigateToChoosingNetworkScene() {
        // forward request to sendTokenViewModel
        sendTokenViewModel.navigate(to: .chooseNetwork)
    }
    
    func userDidTapPaste() {
        search(UIPasteboard.general.string)
    }
    
    func search(_ address: String?) {
        searchTextSubject.accept(address)
        if recipientsListViewModel.searchString != address {
            recipientsListViewModel.searchString = address
            recipientsListViewModel.reload()
        }
    }
    
    func selectRecipient(_ recipient: SendToken.Recipient) {
        sendTokenViewModel.selectRecipient(recipient)
        inputStateSubject.accept(.recipientSelected)
    }
    
    func clearRecipient() {
        inputStateSubject.accept(.searching)
        sendTokenViewModel.selectRecipient(nil)
    }
    
    func next() {
        nextHandler?()
    }
}
