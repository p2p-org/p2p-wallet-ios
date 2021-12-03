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
    var recipientsListViewModel: SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientsListViewModel {get}
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?> {get}
    var inputStateDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState> {get}
    var searchTextDriver: Driver<String?> {get}
    var recipientDriver: Driver<SendToken.Recipient?> {get}
    var networkDriver: Driver<SendToken.Network> {get}
    var feeDriver: Driver<SendToken.Fee> {get}
    var isValidDriver: Driver<Bool> {get}
    
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene)
    
    func userDidTapPaste()
    func search(_ address: String?)
    
    func selectRecipient(_ recipient: SendToken.Recipient)
    func clearRecipient()
    
    func getSelectableNetwork() -> [SendToken.Network]
    func getSelectedNetwork() -> SendToken.Network
    func selectNetwork(_ network: SendToken.Network)
    func getRenBTCPrice() -> Double
    
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
        var solanaAPIClient: SendTokenAPIClient! {
            didSet {
                recipientsListViewModel.solanaAPIClient = solanaAPIClient
            }
        }
        var pricesService: PricesServiceType!
        var wallet: SolanaSDK.Wallet!
        var completion: ((SendToken.Recipient, SendToken.Network) -> Void)?
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        let recipientsListViewModel = RecipientsListViewModel()
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let inputStateSubject = BehaviorRelay<InputState>(value: .searching)
        private let searchTextSubject = BehaviorRelay<String?>(value: nil)
        private let recipientSubject = BehaviorRelay<SendToken.Recipient?>(value: nil)
        private let networkSubject = BehaviorRelay<SendToken.Network>(value: .solana)
        private let feeSubject = BehaviorRelay<SendToken.Fee>(value: SendToken.Network.solana.defaultFee)
        
        init() {
            bind()
        }
        
        private func bind() {
            networkSubject
                .skip(1)
                .subscribe(onNext: {[weak self] network in
                    switch network {
                    case .solana:
                        self?.feeSubject.accept(.init(amount: 0, unit: Defaults.fiat.symbol))
                    case .bitcoin:
                        self?.feeSubject.accept(.init(amount: 0.0002, unit: "renBTC"))
                    }
                })
                .disposed(by: disposeBag)
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
    
    var recipientDriver: Driver<SendToken.Recipient?> {
        recipientSubject.asDriver()
    }
    
    var networkDriver: Driver<SendToken.Network> {
        networkSubject.asDriver()
    }
    
    var feeDriver: Driver<SendToken.Fee> {
        feeSubject.asDriver()
    }
    
    var isValidDriver: Driver<Bool> {
        recipientSubject.map {$0 != nil}
            .asDriver(onErrorJustReturn: false)
    }
    
    // MARK: - Actions
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene) {
        navigationSubject.accept(scene)
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
        recipientSubject.accept(recipient)
        inputStateSubject.accept(.recipientSelected)
        
        if isRecipientBTCAddress() {
            networkSubject.accept(.bitcoin)
        } else {
            networkSubject.accept(.solana)
        }
    }
    
    func clearRecipient() {
        inputStateSubject.accept(.searching)
        recipientSubject.accept(nil)
    }
    
    func getSelectableNetwork() -> [SendToken.Network] {
        var networks: [SendToken.Network] = [.solana]
        if isRecipientBTCAddress() {
            networks.append(.bitcoin)
        }
        return networks
    }
    
    func getSelectedNetwork() -> SendToken.Network {
        networkSubject.value
    }
    
    func selectNetwork(_ network: SendToken.Network) {
        if !wallet.token.isRenBTC {
            networkSubject.accept(.solana)
        }
        networkSubject.accept(network)
    }
    
    func getRenBTCPrice() -> Double {
        pricesService.currentPrice(for: "renBTC")?.value ?? 0
    }
    
    private func isRecipientBTCAddress() -> Bool {
        guard let recipient = recipientSubject.value else {return false}
        return recipient.name == nil &&
            recipient.address
                .matches(oneOfRegexes: .bitcoinAddress(isTestnet: solanaAPIClient.isTestNet()))
    }
    
    func next() {
        let network = networkSubject.value
        guard let recipient = recipientSubject.value else {return}
        completion?(recipient, network)
    }
}
