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
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
    func getSelectedWallet() -> SolanaSDK.Wallet?
    func getSelectedAmount() -> Double?
}

extension SendToken.ChooseRecipientAndNetwork {
    class ViewModel {
        // MARK: - Dependencies
        var solanaAPIClient: SendTokenAPIClient!
        var repository: WalletsRepository!
        var pricesService: PricesServiceType!
        
        // MARK: - Properties
        var selectedWalletPubkey: String!
        var selectedAmount: SolanaSDK.Lamports!
        
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
    
    func createSelectAddressViewModel() -> SendTokenChooseRecipientAndNetworkSelectAddressViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewModel()
        vm.solanaAPIClient = solanaAPIClient
        vm.pricesService = pricesService
        vm.wallet = getSelectedWallet()
        return vm
    }
    
    func getSelectedWallet() -> SolanaSDK.Wallet? {
        repository.getWallets().first(where: {$0.pubkey == selectedWalletPubkey})
    }
    
    func getSelectedAmount() -> Double? {
        selectedAmount.convertToBalance(decimals: getSelectedWallet()?.token.decimals)
    }
}
