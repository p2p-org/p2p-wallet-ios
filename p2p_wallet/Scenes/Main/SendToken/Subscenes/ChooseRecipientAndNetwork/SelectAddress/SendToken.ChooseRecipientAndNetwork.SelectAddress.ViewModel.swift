//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import RxSwift
import RxCocoa
import SolanaSwift

protocol SendTokenChooseRecipientAndNetworkSelectAddressViewModelType: WalletDidSelectHandler {
    var relayMethod: SendTokenRelayMethod {get}
    var showAfterConfirmation: Bool {get}
    var preSelectedNetwork: SendToken.Network? {get}
    var recipientsListViewModel: SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientsListViewModel {get}
    var navigationDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene?> {get}
    var inputStateDriver: Driver<SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState> {get}
    var searchTextDriver: Driver<String?> {get}
    var walletDriver: Driver<Wallet?> {get}
    var recipientDriver: Driver<SendToken.Recipient?> {get}
    var networkDriver: Driver<SendToken.Network> {get}
    var feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>> {get}
    var isValidDriver: Driver<Bool> {get}
    
    func getCurrentInputState() -> SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState
    func getCurrentSearchKey() -> String?
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
        private let chooseRecipientAndNetworkViewModel: SendTokenChooseRecipientAndNetworkViewModelType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        let relayMethod: SendTokenRelayMethod
        private let disposeBag = DisposeBag()
        let recipientsListViewModel = RecipientsListViewModel()
        let showAfterConfirmation: Bool
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let inputStateSubject = BehaviorRelay<InputState>(value: .searching)
        private let searchTextSubject = BehaviorRelay<String?>(value: nil)
        
        init(chooseRecipientAndNetworkViewModel: SendTokenChooseRecipientAndNetworkViewModelType, showAfterConfirmation: Bool, relayMethod: SendTokenRelayMethod) {
            self.relayMethod = relayMethod
            self.chooseRecipientAndNetworkViewModel = chooseRecipientAndNetworkViewModel
            self.showAfterConfirmation = showAfterConfirmation
            recipientsListViewModel.solanaAPIClient = chooseRecipientAndNetworkViewModel.getSendService()
            recipientsListViewModel.preSelectedNetwork = preSelectedNetwork
            
            if chooseRecipientAndNetworkViewModel.getSelectedRecipient() != nil {
                if showAfterConfirmation {
                    inputStateSubject.accept(.recipientSelected)
                } else {
                    clearRecipient()
                }
            }
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
    var preSelectedNetwork: SendToken.Network? {
        chooseRecipientAndNetworkViewModel.preSelectedNetwork
    }
    
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
        chooseRecipientAndNetworkViewModel.walletDriver
    }
    
    var recipientDriver: Driver<SendToken.Recipient?> {
        chooseRecipientAndNetworkViewModel.recipientDriver
    }
    
    var networkDriver: Driver<SendToken.Network> {
        chooseRecipientAndNetworkViewModel.networkDriver
    }
    
    var feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>> {
        chooseRecipientAndNetworkViewModel.feeInfoDriver
    }
    
    var isValidDriver: Driver<Bool> {
        var conditionDrivers: [Driver<Bool>] = [
            recipientDriver.map {$0 != nil}
        ]
        
        conditionDrivers.append(
            Driver.combineLatest(
                networkDriver,
                feeInfoDriver
            )
                .map {[weak self] network, feeInfo -> Bool in
                    guard let self = self else {return false}
                    switch network {
                    case .solana:
                        switch self.relayMethod {
                        case .relay:
                            guard let value = feeInfo.value else {
                                return false
                            }
                            
                            if value.feeAmount.total == 0 {
                                return true
                            } else {
                                return value.isValid
                            }
                        case .reward:
                            return true
                        }
                    case .bitcoin:
                        return true
                    }
                }
        )
        
        return Driver.combineLatest(conditionDrivers)
            .map {$0.allSatisfy {$0}}
    }
    
    func getCurrentInputState() -> SendToken.ChooseRecipientAndNetwork.SelectAddress.InputState {
        inputStateSubject.value
    }
    
    func getCurrentSearchKey() -> String? {
        searchTextSubject.value
    }
    
    func getPrice(for symbol: String) -> Double {
        chooseRecipientAndNetworkViewModel.getPrice(for: symbol)
    }
    
    func getSOLAndRenBTCPrices() -> [String: Double] {
        chooseRecipientAndNetworkViewModel.getSOLAndRenBTCPrices()
    }
    
    // MARK: - Actions
    func navigate(to scene: SendToken.ChooseRecipientAndNetwork.SelectAddress.NavigatableScene) {
        if scene == .selectPayingWallet {
            analyticsManager.log(event: .tokenListViewed(lastScreen: "Send", tokenListLocation: "Fee"))
        }
        navigationSubject.accept(scene)
    }
    
    func navigateToChoosingNetworkScene() {
        // forward request to chooseRecipientAndNetworkViewModel
        chooseRecipientAndNetworkViewModel.navigate(to: .chooseNetwork)
    }
    
    func userDidTapPaste() {
        search(clipboardManager.stringFromClipboard())
    }
    
    func walletDidSelect(_ wallet: Wallet) {
        chooseRecipientAndNetworkViewModel.selectPayingWallet(wallet)
    }
    
    func search(_ address: String?) {
        searchTextSubject.accept(address)
        if recipientsListViewModel.searchString != address {
            recipientsListViewModel.searchString = address
            recipientsListViewModel.reload()
        }
    }
    
    func selectRecipient(_ recipient: SendToken.Recipient) {
        chooseRecipientAndNetworkViewModel.selectRecipient(recipient)
        inputStateSubject.accept(.recipientSelected)
    }
    
    func clearRecipient() {
        inputStateSubject.accept(.searching)
        chooseRecipientAndNetworkViewModel.selectRecipient(nil)
    }
    
    func next() {
        chooseRecipientAndNetworkViewModel.save()
        chooseRecipientAndNetworkViewModel.navigateNext()
    }
}
