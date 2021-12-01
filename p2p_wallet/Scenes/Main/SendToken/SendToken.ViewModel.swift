//
//  SendToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendTokenViewModelType {
    var navigationDriver: Driver<SendToken.NavigatableScene> {get}
    
    func createChooseTokenAndAmountViewModel() -> SendTokenChooseTokenAndAmountViewModelType
    func createChooseRecipientAndNetworkViewModel() -> SendTokenChooseRecipientAndNetworkViewModelType
    
    func navigate(to scene: SendToken.NavigatableScene)
}

extension SendToken {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var addressFormatter: AddressFormatterType
        private let walletsRepository: WalletsRepository
        var solanaAPIClient: SendTokenAPIClient
        let pricesService: PricesServiceType
        
        // MARK: - Properties
        private let initialWalletPubkey: String?
        private let initialDestinationWalletPubkey: String?
        
        private var selectedWalletPubkey: String?
        private var selectedAmount: SolanaSDK.Lamports?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene>(value: .chooseTokenAndAmount)
        
        // MARK: - Initializers
        init(
            repository: WalletsRepository,
            pricesService: PricesServiceType,
            walletPubkey: String?,
            destinationAddress: String?,
            apiClient: SendTokenAPIClient,
            renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        ) {
            self.walletsRepository = repository
            self.pricesService = pricesService
            self.initialWalletPubkey = walletPubkey
            self.initialDestinationWalletPubkey = destinationAddress
            self.solanaAPIClient = apiClient
        }
    }
}

extension SendToken.ViewModel: SendTokenViewModelType {
    var navigationDriver: Driver<SendToken.NavigatableScene> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func createChooseTokenAndAmountViewModel() -> SendTokenChooseTokenAndAmountViewModelType {
        let vm = SendToken.ChooseTokenAndAmount.ViewModel(repository: walletsRepository, walletPubkey: initialWalletPubkey)
        vm.onGoBack = {[weak self] in
            self?.navigate(to: .back)
        }
        vm.onSelect = {[weak self] pubkey, lamports in
            self?.selectedWalletPubkey = pubkey
            self?.selectedAmount = lamports
            self?.navigate(to: .chooseRecipientAndNetwork)
        }
        return vm
    }
    
    func createChooseRecipientAndNetworkViewModel() -> SendTokenChooseRecipientAndNetworkViewModelType {
        let vm = SendToken.ChooseRecipientAndNetwork.ViewModel()
        vm.solanaAPIClient = solanaAPIClient
        vm.repository = walletsRepository
        vm.selectedWalletPubkey = selectedWalletPubkey
        vm.selectedAmount = selectedAmount
        vm.pricesService = pricesService
        return vm
    }
    
    func navigate(to scene: SendToken.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
