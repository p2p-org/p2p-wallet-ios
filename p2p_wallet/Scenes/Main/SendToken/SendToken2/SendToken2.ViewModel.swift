//
//  SendToken2.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SendToken2ViewModelType {
    var navigationDriver: Driver<SendToken2.NavigatableScene> {get}
    
    func createChooseTokenAndAmountViewModel() -> SendTokenChooseTokenAndAmountViewModelType
    
    func navigate(to scene: SendToken2.NavigatableScene)
}

extension SendToken2 {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var addressFormatter: AddressFormatterType
        private let walletsRepository: WalletsRepository
        
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
            walletPubkey: String?,
            destinationAddress: String?,
            apiClient: SendTokenAPIClient,
            renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        ) {
            self.walletsRepository = repository
            self.initialWalletPubkey = walletPubkey
            self.initialDestinationWalletPubkey = destinationAddress
        }
    }
}

extension SendToken2.ViewModel: SendToken2ViewModelType {
    var navigationDriver: Driver<SendToken2.NavigatableScene> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func createChooseTokenAndAmountViewModel() -> SendTokenChooseTokenAndAmountViewModelType {
        let vm = SendTokenChooseTokenAndAmount.ViewModel(repository: walletsRepository, walletPubkey: initialWalletPubkey)
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
    
    func navigate(to scene: SendToken2.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
