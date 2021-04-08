//
//  TransactionInfoViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import RxSwift
import RxCocoa

enum TransactionInfoNavigatableScene {
    case explorer
}

class TransactionInfoViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<TransactionInfoNavigatableScene>()
    let showDetailTransaction = BehaviorRelay<Bool>(value: false)
    let transaction: BehaviorRelay<SolanaSDK.AnyTransaction>
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(transaction: SolanaSDK.AnyTransaction) {
        self.transaction = BehaviorRelay<SolanaSDK.AnyTransaction>(value: transaction)
    }
    
    // MARK: - Actions
    @objc func showExplorer() {
        navigationSubject.onNext(.explorer)
    }
    
    @objc func copySignatureToClipboard() {
        UIApplication.shared.copyToClipboard(transaction.value.signature)
    }
    
    @objc func copySourceAddressToClipboard() {
//        UIApplication.shared.copyToClipboard(transaction.value.signature)
    }
    
    @objc func copyDestinationAddressToClipboard() {
//        UIApplication.shared.copyToClipboard(transaction.value.signature)
    }
}
