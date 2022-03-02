//
//  PT.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol PTViewModelType {
    var navigationDriver: Driver<PT.NavigatableScene?> {get}
    var isSwapping: Bool {get}
    func getTransactionDescription(withAmount: Bool) -> String
    
    func navigate(to scene: PT.NavigatableScene)
}

extension PT {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        
        // MARK: - Properties
        private let processingTransaction: ProcessingTransactionType
        
        // MARK: - Properties
        init(processingTransaction: ProcessingTransactionType) {
            self.processingTransaction = processingTransaction
        }
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension PT.ViewModel: PTViewModelType {
    var navigationDriver: Driver<PT.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var isSwapping: Bool {
        processingTransaction.isSwap
    }
    
    func getTransactionDescription(withAmount: Bool) -> String {
        switch processingTransaction {
        case let transaction as PT.SendTransaction:
            var desc = transaction.sender.token.symbol + " → " + (transaction.receiver.name ?? transaction.receiver.address.truncatingMiddle(numOfSymbolsRevealed: 4))
            if withAmount {
                let amount = transaction.amount.convertToBalance(decimals: transaction.sender.token.decimals)
                    .toString(maximumFractionDigits: 9)
                desc = amount + " " + desc
            }
            return desc
        default:
            return ""
        }
    }
    
    // MARK: - Actions
    func navigate(to scene: PT.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
